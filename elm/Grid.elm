module Grid exposing (..)

import Matrix
import Matrix.Custom
import Matrix.Extra
import Random.Pcg as Random exposing (Seed)
import Set exposing (Set)
import Types exposing (..)


minWidth : Int
minWidth =
    9


maxWidth : Int
maxWidth =
    32


minHeight : Int
minHeight =
    9


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


clampWidth : Int -> Int
clampWidth =
    clamp minWidth maxWidth


clampHeight : Int -> Int
clampHeight =
    clamp minHeight maxHeight


clampNumMines : Int -> Int -> Int -> Int
clampNumMines width height =
    clamp minNumMines (maxNumMines width height)


defaultGrid : Int -> Int -> Grid
defaultGrid width height =
    Matrix.repeat width height defaultCell


defaultCell : Cell
defaultCell =
    Cell Unrevealed (Hint 0)


reset : Grid -> Grid
reset grid =
    defaultGrid (Matrix.width grid) (Matrix.height grid)


addRandomMinesAndUpdateNumbers :
    Int
    -> Set ( Int, Int )
    -> ( Seed, Grid )
    -> ( Seed, Grid )
addRandomMinesAndUpdateNumbers numMines excludedCoords ( seed, grid ) =
    let
        ( newSeed, newGrid ) =
            addRandomMines numMines excludedCoords ( seed, grid )
    in
        ( newSeed, setGridNumbers newGrid )


addRandomMines : Int -> Set ( Int, Int ) -> ( Seed, Grid ) -> ( Seed, Grid )
addRandomMines numMines excludedCoords ( seed, grid ) =
    List.foldl
        (always (addRandomMine excludedCoords))
        ( seed, grid )
        (List.range 1 numMines)


addRandomMine : Set ( Int, Int ) -> ( Seed, Grid ) -> ( Seed, Grid )
addRandomMine excludedCoords ( seed, grid ) =
    let
        isAvailable ( x, y ) =
            case Matrix.get x y grid of
                Just (Cell Unrevealed (Hint _)) ->
                    not (Set.member ( x, y ) excludedCoords)

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
    Matrix.update x y (setCellState Revealed) grid


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
            Just (Cell Unrevealed (Hint number)) ->
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


detonateAll : Grid -> Grid
detonateAll =
    Matrix.map detonateCell


detonateCell : Cell -> Cell
detonateCell cell =
    case cell of
        Cell Unrevealed Mine ->
            Cell Revealed Mine

        _ ->
            cell


flag : Int -> Int -> Grid -> Grid
flag x y grid =
    case Matrix.get x y grid of
        Just (Cell Unrevealed _) ->
            Matrix.update x y (setCellState Flagged) grid

        Just (Cell Flagged _) ->
            Matrix.update x y (setCellState Unrevealed) grid

        _ ->
            grid


setCellState : CellState -> Cell -> Cell
setCellState cellState (Cell _ cellInner) =
    Cell cellState cellInner


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
isCellMine (Cell _ cellInner) =
    cellInner == Mine


isCellRevealedMine : Cell -> Bool
isCellRevealedMine (Cell cellState cellInner) =
    cellState == Revealed && cellInner == Mine


isCellUnrevealed : Cell -> Bool
isCellUnrevealed (Cell cellState _) =
    cellState == Unrevealed


isCellFlagged : Cell -> Bool
isCellFlagged (Cell cellState _) =
    cellState == Flagged


isCellCorrectlyMarked : Cell -> Bool
isCellCorrectlyMarked cell =
    case cell of
        Cell Flagged Mine ->
            True

        Cell Revealed (Hint _) ->
            True

        _ ->
            False
