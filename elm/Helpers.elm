module Helpers exposing (..)

import Array
import Constants
import Html exposing (Attribute)
import Html.Events
import Json.Decode exposing (Decoder)
import Matrix exposing (Matrix)
import Matrix.Extra
import Random.Pcg as Random exposing (Seed)
import Set exposing (Set)
import Types exposing (..)


maxNumMines : number -> number -> number
maxNumMines width height =
    width * height - 1


clampWidth : Int -> Int
clampWidth =
    clamp Constants.minWidth Constants.maxWidth


clampHeight : Int -> Int
clampHeight =
    clamp Constants.minHeight Constants.maxHeight


clampNumMines : Int -> Int -> Int -> Int
clampNumMines width height =
    clamp Constants.minNumMines (maxNumMines width height)


clampSizerWidth : Int -> Int
clampSizerWidth =
    clamp
        (calculateSizerSize Constants.minWidth)
        (calculateSizerSize Constants.maxWidth)


clampSizerHeight : Int -> Int
clampSizerHeight =
    clamp
        (calculateSizerSize Constants.minHeight)
        (calculateSizerSize Constants.maxHeight)


calculateSizerSize : Int -> Int
calculateSizerSize size =
    (size * (Constants.cellSize + Constants.cellSpacing))
        + Constants.cellSpacing
        + (Constants.sizerOffset * 2)


emptyCell : Cell
emptyCell =
    Cell (Hint 0) Unrevealed


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
                Just (Cell (Hint _) Unrevealed) ->
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


addRandomMinesAndUpdateNumbers : Int -> Seed -> Grid -> ( Seed, Grid )
addRandomMinesAndUpdateNumbers numMines seed grid =
    let
        ( newSeed, gridWithMines ) =
            addRandomMines numMines seed grid

        finalGrid =
            updateGridNumbers gridWithMines
    in
        ( newSeed, finalGrid )


updateGridNumbers : Grid -> Grid
updateGridNumbers grid =
    Matrix.indexedMap (updateCellNumber grid) grid


updateCellNumber : Grid -> Int -> Int -> Cell -> Cell
updateCellNumber grid columnNumber rowNumber cell =
    case cell of
        Cell Mine _ ->
            cell

        Cell (Hint _) cellState ->
            let
                number =
                    calculateCellNumber columnNumber rowNumber grid
            in
                Cell (Hint number) cellState


calculateCellNumber : Int -> Int -> Grid -> Int
calculateCellNumber columnNumber rowNumber grid =
    Matrix.Extra.neighbours columnNumber rowNumber grid
        |> List.filter isMine
        |> List.length


reveal : Int -> Int -> Grid -> Grid
reveal columnNum rowNum grid =
    let
        maybeCell =
            Matrix.get columnNum rowNum grid
    in
        case maybeCell of
            Just (Cell (Hint 0) _) ->
                recursivelyReveal columnNum rowNum grid

            Just _ ->
                Matrix.update columnNum rowNum markRevealed grid

            Nothing ->
                grid


markRevealed : Cell -> Cell
markRevealed (Cell innerCell _) =
    Cell innerCell Revealed


recursivelyReveal : Int -> Int -> Grid -> Grid
recursivelyReveal columnNum rowNum grid =
    let
        ( _, newGrid ) =
            recursivelyRevealHelper Set.empty columnNum rowNum grid
    in
        newGrid


recursivelyRevealHelper : Set ( Int, Int ) -> Int -> Int -> Grid -> ( Set ( Int, Int ), Grid )
recursivelyRevealHelper visitedCoords columnNum rowNum grid =
    if Set.member ( columnNum, rowNum ) visitedCoords then
        ( visitedCoords, grid )
    else
        let
            maybeCell =
                Matrix.get columnNum rowNum grid
        in
            case maybeCell of
                Just (Cell (Hint number) _) ->
                    let
                        newGrid =
                            Matrix.update columnNum rowNum markRevealed grid

                        newVisitedCoords =
                            Set.insert ( columnNum, rowNum ) visitedCoords

                        neighbours =
                            Matrix.Extra.indexedNeighbours columnNum rowNum newGrid

                        markNeighbour ( ( x, y ), _ ) ( icoords, igrid ) =
                            recursivelyRevealHelper icoords x y igrid
                    in
                        if number == 0 then
                            List.foldl markNeighbour ( newVisitedCoords, newGrid ) neighbours
                        else
                            ( newVisitedCoords, newGrid )

                _ ->
                    ( visitedCoords, grid )


isMine : Cell -> Bool
isMine cell =
    case cell of
        Cell Mine _ ->
            True

        _ ->
            False


isUnrevealed : Cell -> Bool
isUnrevealed (Cell _ cellState) =
    cellState == Unrevealed


isFailed : Cell -> Bool
isFailed (Cell innerCell cellState) =
    innerCell == Mine && cellState == Revealed


cellToString : Cell -> String
cellToString cell =
    case cell of
        Cell Mine _ ->
            "X"

        Cell (Hint num) _ ->
            if num == 0 then
                ""
            else
                toString num


gridState : Grid -> GridState
gridState grid =
    if isGridEmpty grid then
        NewGrid
    else if isGridFinished grid then
        WonGrid
    else if isGridFailed grid then
        LostGrid
    else
        OngoingGrid


isGridEmpty : Grid -> Bool
isGridEmpty =
    matrixCheckEveryElement isUnrevealed


isGridFailed : Grid -> Bool
isGridFailed =
    matrixCheckAnyElement isFailed


isGridFinished : Grid -> Bool
isGridFinished =
    matrixCheckEveryElement isCellFinished


isCellFinished : Cell -> Bool
isCellFinished (Cell innerCell cellState) =
    case ( innerCell, cellState ) of
        ( Mine, Flagged ) ->
            True

        ( Hint _, Revealed ) ->
            True

        _ ->
            False


matrixCheckAnyElement : (a -> Bool) -> Matrix a -> Bool
matrixCheckAnyElement fn matrix =
    let
        matchingElements =
            Matrix.filter fn matrix
    in
        Array.length matchingElements > 0


matrixCheckEveryElement : (a -> Bool) -> Matrix a -> Bool
matrixCheckEveryElement fn =
    not << matrixCheckAnyElement (not << fn)


matrixToListsOfLists : Matrix a -> List (List a)
matrixToListsOfLists matrix =
    List.range 0 (Matrix.height matrix - 1)
        |> List.filterMap (\rowIndex -> Matrix.getRow rowIndex matrix)
        |> List.map Array.toList


calculatePointerMovement : Sizer -> Maybe PointerPosition -> PointerMovement
calculatePointerMovement sizer maybePointerPosition =
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
            { dx = 0
            , dy = 0
            }


calculateSize : Int -> Int -> Int
calculateSize size movement =
    size + floor ((toFloat movement) / (Constants.cellSize + Constants.cellSpacing))


onMouseDown : (PointerPosition -> msg) -> Attribute msg
onMouseDown tagger =
    Html.Events.on "mousedown"
        (Json.Decode.map tagger pointerPositionDecoder)


onMouseMove : (PointerPosition -> msg) -> Attribute msg
onMouseMove tagger =
    Html.Events.on "mousemove"
        (Json.Decode.map tagger pointerPositionDecoder)


pointerPositionDecoder : Decoder PointerPosition
pointerPositionDecoder =
    Json.Decode.map2 PointerPosition
        (Json.Decode.field "screenX" Json.Decode.int)
        (Json.Decode.field "screenY" Json.Decode.int)


onChange : (String -> msg) -> Attribute msg
onChange tagger =
    Html.Events.on "change"
        (Json.Decode.map tagger Html.Events.targetValue)
