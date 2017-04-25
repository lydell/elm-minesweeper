module Encoders exposing (..)

import Grid
import Json.Encode as Encode exposing (Value)
import Types exposing (..)


modelEncoder : Model -> Value
modelEncoder model =
    Encode.object
        [ ( "givenUp", Encode.bool model.givenUp )
        , ( "grid", gridEncoder model.grid )
        , ( "selectedCell", selectedCellEncoder model.selectedCell )
        ]


gridEncoder : Grid -> Value
gridEncoder grid =
    Grid.toListOfLists grid
        |> List.map rowEncoder
        |> Encode.list


rowEncoder : List Cell -> Value
rowEncoder row =
    row
        |> List.map cellEncoder
        |> Encode.list


cellEncoder : Cell -> Value
cellEncoder (Cell cellState cellInner) =
    Encode.list
        [ Encode.string (toString cellState)
        , Encode.string (toString cellInner)
        ]


selectedCellEncoder : Maybe ( Int, Int ) -> Value
selectedCellEncoder selectedCell =
    case selectedCell of
        Just ( x, y ) ->
            Encode.list [ Encode.int x, Encode.int y ]

        Nothing ->
            Encode.null
