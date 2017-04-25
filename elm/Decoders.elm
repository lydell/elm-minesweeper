module Decoders exposing (..)

import Grid
import Json.Decode as Decode exposing (Decoder)
import Types exposing (..)


localStorageModelDecoder : Decoder LocalStorageModel
localStorageModelDecoder =
    Decode.map3 LocalStorageModel
        (Decode.field "givenUp" Decode.bool)
        (Decode.field "grid" gridDecoder)
        (Decode.field "selectedCell" selectedCellDecoder)


gridDecoder : Decoder Grid
gridDecoder =
    Decode.map gridMapper (Decode.list rowDecoder)


gridMapper : List (List Cell) -> Grid
gridMapper listOfLists =
    Grid.fromList listOfLists
        |> Maybe.withDefault (Grid.defaultGrid Grid.minWidth Grid.maxWidth)


rowDecoder : Decoder (List Cell)
rowDecoder =
    Decode.list cellDecoder


cellDecoder : Decoder Cell
cellDecoder =
    Decode.map2 Cell
        (Decode.index 0 (Decode.map parseCellState Decode.string))
        (Decode.index 1 (Decode.map parseCellInner Decode.string))


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
    Decode.map2 (,)
        (Decode.index 0 Decode.int)
        (Decode.index 1 Decode.int)
        |> Decode.nullable
