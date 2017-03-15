module View exposing (view)

import Helpers
import Html
    exposing
        ( Html
        , button
        , div
        , input
        , span
        , table
        , tbody
        , td
        , text
        , tr
        )
import Html.Attributes
    exposing
        ( attribute
        , class
        , defaultValue
        , style
        , type_
        )
import Html.Events exposing (onInput)
import Matrix
import Types
    exposing
        ( Cell
        , Grid
        , Model
        , Msg
            ( HeightInput
            , NumMinesInput
            , WidthInput
            )
        )


view : Model -> Html Msg
view model =
    div [ class "Container" ]
        [ viewGrid model.grid
        , viewForm model
        ]


viewGrid : Grid -> Html Msg
viewGrid grid =
    table [ class "Grid" ]
        [ tbody []
            (List.map viewRow (Helpers.matrixToListsOfLists grid))
        ]


viewRow : List Cell -> Html Msg
viewRow row =
    tr []
        (List.map viewCell row)


viewCell : Cell -> Html msg
viewCell cell =
    let
        styles =
            [ ( "width", (toString Helpers.cellWidth) ++ "px" )
            , ( "height", (toString Helpers.cellHeight) ++ "px" )
            ]
    in
        td []
            [ button [ type_ "button", class "Cell", style styles ]
                [ text (Helpers.cellToString cell) ]
            ]


viewForm : Model -> Html Msg
viewForm model =
    let
        width =
            Matrix.width model.grid

        height =
            Matrix.height model.grid
    in
        div [ class "Form" ]
            [ viewNumberInput width
                Helpers.minWidth
                Helpers.maxWidth
                WidthInput
            , text "×"
            , viewNumberInput height
                Helpers.minHeight
                Helpers.maxHeight
                HeightInput
            , text "with"
            , viewNumberInput model.numMines
                Helpers.minNumMines
                (Helpers.maxNumMines width height)
                NumMinesInput
            ]


viewNumberInput : Int -> Int -> Int -> (String -> Msg) -> Html Msg
viewNumberInput defaultValue_ minValue maxValue tagger =
    let
        styles =
            [ ( "width", toString (String.length (toString defaultValue_)) ++ "ch" ) ]
    in
        span [ class "NumberInput" ]
            [ input
                [ type_ "tel"
                , defaultValue (toString defaultValue_)
                , attribute "data-min" (toString minValue)
                , attribute "data-max" (toString maxValue)
                , onInput tagger
                , class "NumberInput-input"
                , style styles
                ]
                []
            , text (toString minValue ++ "–" ++ toString maxValue)
            ]
