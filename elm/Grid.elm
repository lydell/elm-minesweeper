module Grid exposing (..)

import Array
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
    width * height - 9


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


numMines : Grid -> Int
numMines grid =
    Matrix.filter isCellMine grid
        |> Array.length


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
    Cell Unrevealed Hint


createGrid : Int -> Int -> Int -> Set ( Int, Int ) -> Seed -> ( Seed, Grid )
createGrid width height numMines_ excludedCoords seed =
    addRandomMines numMines_ excludedCoords ( seed, defaultGrid width height )


addRandomMines : Int -> Set ( Int, Int ) -> ( Seed, Grid ) -> ( Seed, Grid )
addRandomMines numMines_ excludedCoords ( seed, grid ) =
    List.foldl
        (always (addRandomMine excludedCoords))
        ( seed, grid )
        (List.range 1 numMines_)


addRandomMine : Set ( Int, Int ) -> ( Seed, Grid ) -> ( Seed, Grid )
addRandomMine excludedCoords ( seed, grid ) =
    let
        isAvailable ( x, y ) =
            case Matrix.get x y grid of
                Just (Cell Unrevealed Hint) ->
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


cellNumber : Int -> Int -> Grid -> Int
cellNumber x y grid =
    Matrix.Extra.neighbours x y grid
        |> List.filter isCellMine
        |> List.length


reveal : Int -> Int -> Grid -> Grid
reveal x y grid =
    case Matrix.get x y grid of
        Just (Cell Unrevealed cellInner) ->
            if cellInner == Hint && cellNumber x y grid == 0 then
                revealRecursively x y grid
            else
                revealSingle x y grid

        _ ->
            grid


revealNeighbours : Int -> Int -> Grid -> Grid
revealNeighbours x y grid =
    case Matrix.get x y grid of
        Just (Cell _ Hint) ->
            let
                number =
                    cellNumber x y grid

                neighbours =
                    Matrix.Extra.indexedNeighbours x y grid

                neighbourCells =
                    List.map Tuple.second neighbours

                flags =
                    List.filter isCellFlagged neighbourCells

                neighbourCoords =
                    List.map Tuple.first neighbours
            in
                if number == 0 || List.length flags /= number then
                    grid
                else
                    List.foldl (uncurry reveal) grid neighbourCoords

        _ ->
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
            Just (Cell Unrevealed Hint) ->
                let
                    number =
                        cellNumber x y grid

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


gridState : Bool -> Grid -> GridState
gridState givenUp grid =
    if givenUp then
        GivenUpGrid
    else if isGridNew grid then
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
        Cell cellState Mine ->
            cellState /= Revealed

        Cell cellState Hint ->
            cellState == Revealed


isGameEnd : GridState -> Bool
isGameEnd gridState =
    gridState == WonGrid || gridState == LostGrid || gridState == GivenUpGrid
