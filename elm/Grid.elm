module Grid exposing (..)

import Html.Events.Custom exposing (PointerPosition)
import Matrix
import Matrix.Custom
import Matrix.Extra
import Random.Pcg as Random exposing (Seed)
import Set exposing (Set)
import Types exposing (..)


minWidth : Int
minWidth =
    2


maxWidth : Int
maxWidth =
    32


minHeight : Int
minHeight =
    2


maxHeight : Int
maxHeight =
    32


minNumMines : Int
minNumMines =
    1


maxNumMines : Int -> Int -> Int
maxNumMines width height =
    width * height - 1


{-| Suggests a number of mines for a given size of the grid.

The original game has these presets:

preset       | width | height | # cells | # mines
:------------|------:|-------:|--------:|-------:
Beginner     |     9 |      9 |      81 |     10
Intermediate |    16 |     16 |     256 |     40
Expert       |    30 |     16 |     480 |     99

The number of mines can be described as a function of the number of cells:

    y(x) = ax² + bx + c

Solving the following equation system gives the values of a, b and c:

    y(81) = 10
    y(256) = 40
    y(480) = 99
-}
suggestNumMines : Int -> Int -> Int
suggestNumMines width height =
    let
        a =
            103 / 446880

        b =
            41897 / 446880

        c =
            832 / 931

        x =
            toFloat (width * height)
    in
        a * x ^ 2 + b * x + c |> round |> clampNumMines width height


cellSize : Int
cellSize =
    25


cellSpacing : Int
cellSpacing =
    2


sizerOffset : Int
sizerOffset =
    cellSize // 2


sizerSize : Int -> Int
sizerSize size =
    (size * (cellSize + cellSpacing))
        + cellSpacing
        + (sizerOffset * 2)


gridSize : Int -> Int -> Int
gridSize size movement =
    size + floor (toFloat movement / toFloat (cellSize + cellSpacing))


pointerMovement : Sizer -> Maybe PointerPosition -> PointerMovement
pointerMovement sizer maybePointerPosition =
    case ( sizer, maybePointerPosition ) of
        ( Dragging dragStartData, Just pointerPosition ) ->
            let
                startPosition =
                    dragStartData.pointerPosition
            in
                { dx = (pointerPosition.screenX - startPosition.screenX) * 2
                , dy = (pointerPosition.screenY - startPosition.screenY)
                }

        _ ->
            { dx = 0, dy = 0 }


clampWidth : Int -> Int
clampWidth =
    clamp minWidth maxWidth


clampHeight : Int -> Int
clampHeight =
    clamp minHeight maxHeight


clampNumMines : Int -> Int -> Int -> Int
clampNumMines width height =
    clamp minNumMines (maxNumMines width height)


clampSizerWidth : Int -> Int
clampSizerWidth =
    clamp (sizerSize minWidth) (sizerSize maxWidth)


clampSizerHeight : Int -> Int
clampSizerHeight =
    clamp (sizerSize minHeight) (sizerSize maxHeight)


defaultGrid : Int -> Int -> Grid
defaultGrid width height =
    Matrix.repeat width height defaultCell


defaultCell : Cell
defaultCell =
    Cell Unrevealed (Hint 0)


addRandomMinesAndUpdateNumbers : Int -> Seed -> Grid -> ( Seed, Grid )
addRandomMinesAndUpdateNumbers numMines seed grid =
    let
        ( newSeed, newGrid ) =
            addRandomMines numMines seed grid
    in
        ( newSeed, setGridNumbers newGrid )


addRandomMines : Int -> Seed -> Grid -> ( Seed, Grid )
addRandomMines numMines seed grid =
    if numMines <= 0 then
        ( seed, grid )
    else
        let
            ( newSeed, newGrid ) =
                addRandomMine seed grid
        in
            addRandomMines (numMines - 1) newSeed newGrid


addRandomMine : Seed -> Grid -> ( Seed, Grid )
addRandomMine seed grid =
    let
        isAvailable ( x, y ) =
            case Matrix.get x y grid of
                Just (Cell Unrevealed (Hint _)) ->
                    True

                _ ->
                    False

        xGenerator =
            Random.int 0 (Matrix.width grid)

        yGenerator =
            Random.int 0 (Matrix.height grid)

        coordsGenerator =
            Random.pair xGenerator yGenerator
                |> Random.filter isAvailable

        ( ( x, y ), newSeed ) =
            Random.step coordsGenerator seed

        newGrid =
            Matrix.update x y (always (Cell Unrevealed Mine)) grid
    in
        ( newSeed, newGrid )


setGridNumbers : Grid -> Grid
setGridNumbers grid =
    Matrix.indexedMap (setCellNumber grid) grid


setCellNumber : Grid -> Int -> Int -> Cell -> Cell
setCellNumber grid x y cell =
    case cell of
        Cell _ Mine ->
            cell

        Cell cellState (Hint _) ->
            Cell cellState (Hint (cellNumber x y grid))


cellNumber : Int -> Int -> Grid -> Int
cellNumber x y grid =
    Matrix.Extra.neighbours x y grid
        |> List.filter isCellMine
        |> List.length


reveal : Int -> Int -> Grid -> Grid
reveal x y grid =
    case Matrix.get x y grid of
        Just (Cell _ (Hint 0)) ->
            revealRecursively x y grid

        Just _ ->
            revealSingle x y grid

        Nothing ->
            grid


revealSingle : Int -> Int -> Grid -> Grid
revealSingle x y grid =
    Matrix.update x y revealCell grid


revealCell : Cell -> Cell
revealCell (Cell _ innerCell) =
    Cell Revealed innerCell


revealRecursively : Int -> Int -> Grid -> Grid
revealRecursively x y grid =
    let
        ( _, newGrid ) =
            revealRecursivelyHelper x y ( Set.empty, grid )
    in
        newGrid


revealRecursivelyHelper :
    Int
    -> Int
    -> ( Set ( Int, Int ), Grid )
    -> ( Set ( Int, Int ), Grid )
revealRecursivelyHelper x y ( visitedCoords, grid ) =
    if Set.member ( x, y ) visitedCoords then
        ( visitedCoords, grid )
    else
        case Matrix.get x y grid of
            Just (Cell _ (Hint number)) ->
                let
                    newGrid =
                        revealSingle x y grid

                    newVisitedCoords =
                        Set.insert ( x, y ) visitedCoords

                    neighbours =
                        Matrix.Extra.indexedNeighbours x y newGrid
                            |> List.map Tuple.first
                in
                    if number == 0 then
                        List.foldl
                            (uncurry revealRecursivelyHelper)
                            ( newVisitedCoords, newGrid )
                            neighbours
                    else
                        ( newVisitedCoords, newGrid )

            _ ->
                ( visitedCoords, grid )


gridState : Grid -> GridState
gridState grid =
    if isGridNew grid then
        NewGrid
    else if isGridWon grid then
        WonGrid
    else if isGridLost grid then
        LostGrid
    else
        OngoingGrid


isGridNew : Grid -> Bool
isGridNew =
    Matrix.Custom.all isCellUnrevealed


isGridLost : Grid -> Bool
isGridLost =
    Matrix.Custom.any isCellRevealedMine


isGridWon : Grid -> Bool
isGridWon =
    Matrix.Custom.all isCellCorrectlyMarked


isCellMine : Cell -> Bool
isCellMine cell =
    case cell of
        Cell _ Mine ->
            True

        _ ->
            False


isCellRevealedMine : Cell -> Bool
isCellRevealedMine (Cell cellState innerCell) =
    cellState == Revealed && innerCell == Mine


isCellUnrevealed : Cell -> Bool
isCellUnrevealed (Cell cellState _) =
    cellState == Unrevealed


isCellCorrectlyMarked : Cell -> Bool
isCellCorrectlyMarked (Cell cellState innerCell) =
    case ( cellState, innerCell ) of
        ( Flagged, Mine ) ->
            True

        ( Revealed, Hint _ ) ->
            True

        _ ->
            False


isDragging : Sizer -> Bool
isDragging sizer =
    case sizer of
        Dragging _ ->
            True

        _ ->
            False


cellToString : Cell -> String
cellToString cell =
    case cell of
        Cell _ Mine ->
            "X"

        Cell _ (Hint num) ->
            if num == 0 then
                ""
            else
                toString num
