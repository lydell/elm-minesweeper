module Decoders exposing (..)

import Grid
import Json.Decode as Json exposing (Decoder)
import Types exposing (..)


localStorageModelDecoder : Decoder LocalStorageModel
localStorageModelDecoder =
    Json.map3 LocalStorageModel
        (Json.field "givenUp" Json.bool)
        (Json.field "grid" gridDecoder)
        (Json.field "selectedCell" selectedCellDecoder)


gridDecoder : Decoder Grid
gridDecoder =
    Json.map gridMapper (Json.list rowDecoder)


gridMapper : List (List Cell) -> Grid
gridMapper listOfLists =
    Grid.fromList listOfLists
        |> Maybe.withDefault (Grid.defaultGrid Grid.minWidth Grid.maxWidth)


rowDecoder : Decoder (List Cell)
rowDecoder =
    Json.list cellDecoder


cellDecoder : Decoder Cell
cellDecoder =
    Json.map2 Cell
        (Json.index 0 (Json.map parseCellState Json.string))
        (Json.index 1 (Json.map parseCellInner Json.string))


parseCellState : String -> CellState
parseCellState string =
    case string of
        "Revealed" ->
            Revealed

        "Flagged" ->
            Flagged

        _ ->
            Unrevealed


parseCellInner : String -> CellInner
parseCellInner string =
    case string of
        "Mine" ->
            Mine

        _ ->
            Hint


selectedCellDecoder : Decoder (Maybe ( Int, Int ))
selectedCellDecoder =
    Json.map2 (,)
        (Json.index 0 Json.int)
        (Json.index 1 Json.int)
        |> Json.nullable
