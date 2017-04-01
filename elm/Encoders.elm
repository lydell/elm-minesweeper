module Encoders exposing (..)

import Grid
import Json.Encode as Json exposing (Value)
import Types exposing (..)


modelEncoder : Model -> Value
modelEncoder model =
    Json.object
        [ ( "givenUp", Json.bool model.givenUp )
        , ( "grid", gridEncoder model.grid )
        , ( "selectedCell", selectedCellEncoder model.selectedCell )
        ]


gridEncoder : Grid -> Value
gridEncoder grid =
    Grid.toListOfLists grid
        |> List.map rowEncoder
        |> Json.list


rowEncoder : List Cell -> Value
rowEncoder row =
    row
        |> List.map cellEncoder
        |> Json.list


cellEncoder : Cell -> Value
cellEncoder (Cell cellState cellInner) =
    Json.list
        [ Json.string (toString cellState)
        , Json.string (toString cellInner)
        ]


selectedCellEncoder : Maybe ( Int, Int ) -> Value
selectedCellEncoder selectedCell =
    case selectedCell of
        Just ( x, y ) ->
            Json.list [ Json.int x, Json.int y ]

        Nothing ->
            Json.null
