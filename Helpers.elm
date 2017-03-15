module Helpers exposing (..)

import Matrix exposing (Matrix)
import Random.Pcg as Random exposing (Seed)
import Types exposing (Cell(Cell), Grid, InnerCell(Hint, Mine))


minWidth : number
minWidth =
    1


maxWidth : number
maxWidth =
    32


minHeight : number
minHeight =
    1


maxHeight : number
maxHeight =
    32


minNumMines : number
minNumMines =
    0


maxNumMines : number -> number -> number
maxNumMines width height =
    width * height - 1


emptyCell : Cell
emptyCell =
    Cell (Hint 0) { revealed = False }


createEmptyGrid : Int -> Int -> Grid
createEmptyGrid width height =
    Matrix.repeat width height emptyCell


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
                Just (Cell (Hint _) _) ->
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

        turnToMine (Cell _ cellData) =
            Cell Mine cellData

        newGrid =
            Matrix.update x y turnToMine grid
    in
        ( newSeed, newGrid )


cellToString : Cell -> String
cellToString cell =
    case cell of
        Cell Mine _ ->
            "X"

        Cell (Hint num) _ ->
            toString num
