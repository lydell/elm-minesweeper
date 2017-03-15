module View exposing (view)

import Array
import Helpers
import Html exposing (Html, button, div, input, span, text)
import Html.Attributes exposing (attribute, class, defaultValue, style, type_)
import Html.Events exposing (onInput)
import Matrix
import Types exposing (Cell, Model, Msg(HeightInput, NumMinesInput, WidthInput))


view : Model -> Html Msg
view model =
    let
        width =
            Matrix.width model.grid

        height =
            Matrix.height model.grid

        size =
            "50px"

        columns =
            "repeat(" ++ (toString width) ++ ", " ++ size ++ ")"

        rows =
            "repeat(" ++ (toString height) ++ ", " ++ size ++ ")"

        styles =
            [ ( "grid-template-columns", columns )
            , ( "grid-template-rows", rows )
            ]
    in
        div [ class "Container" ]
            [ div [ class "Grid", style styles ]
                (Matrix.toIndexedArray model.grid
                    |> Array.toList
                    |> List.map (\( _, cell ) -> viewCell cell)
                )
            , div [ class "Form" ]
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


viewCell : Cell -> Html msg
viewCell cell =
    button [ type_ "button", class "Cell" ]
        [ text (Helpers.cellToString cell) ]
