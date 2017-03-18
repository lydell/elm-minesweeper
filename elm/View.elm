module View exposing (view)

import Constants
import Helpers exposing (onChange, onMouseDown, onMouseMove)
import Html
    exposing
        ( Html
        , button
        , div
        , input
        , p
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
        , classList
        , style
        , title
        , type_
        , value
        )
import Html.Events exposing (onInput, onMouseUp)
import Matrix
import Types
    exposing
        ( Cell
        , Grid
        , Model
        , Msg
            ( MouseDown
            , MouseMove
            , MouseUp
            , NumMinesChange
            )
        , PointerPosition
        , Sizer(Dragging)
        )


view : Model -> Html Msg
view model =
    let
        isDragging =
            case model.sizer of
                Dragging _ ->
                    True

                _ ->
                    False

        events =
            if isDragging then
                [ onMouseMove MouseMove, onMouseUp MouseUp ]
            else
                []

        classes =
            classList
                [ ( "Container", True )
                , ( "is-dragging", isDragging )
                ]
    in
        div ([ classes ] ++ events)
            [ viewMinesInfo model.numMines
            , div [ class "GridContainer" ]
                [ viewGrid model.grid
                , viewSizer model.grid model.sizer model.pointerPosition
                ]
            ]


viewGrid : Grid -> Html Msg
viewGrid grid =
    let
        styles =
            [ ( "border-spacing", (toString Constants.cellSpacing) ++ "px" ) ]
    in
        table [ class "Grid", style styles ]
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
        size =
            (toString Constants.cellSize) ++ "px"

        styles =
            [ ( "width", size )
            , ( "height", size )
            ]
    in
        td []
            [ button [ type_ "button", class "Cell", style styles ]
                [ text (Helpers.cellToString cell) ]
            ]


viewSizer : Grid -> Sizer -> Maybe PointerPosition -> Html Msg
viewSizer grid sizer maybePointerPosition =
    let
        gridWidth =
            Matrix.width grid

        gridHeight =
            Matrix.height grid

        { width, height } =
            case sizer of
                Dragging { width, height } ->
                    { width = width, height = height }

                _ ->
                    { width = gridWidth, height = gridHeight }

        pointerMovement =
            Helpers.calculatePointerMovement sizer maybePointerPosition

        newWidth =
            (Helpers.calculateSizerSize width + pointerMovement.dx)
                |> Helpers.clampSizerWidth

        newHeight =
            (Helpers.calculateSizerSize height + pointerMovement.dy)
                |> Helpers.clampSizerHeight

        styles =
            [ ( "top", toString -Constants.sizerOffset ++ "px" )
            , ( "width", toString newWidth ++ "px" )
            , ( "height", toString newHeight ++ "px" )
            ]

        buttonSize =
            toString Constants.cellSize ++ "px"

        buttonStyles =
            [ ( "width", buttonSize )
            , ( "height", buttonSize )
            ]
    in
        div [ class "Sizer", style styles ]
            [ p [ class "Sizer-dimensions" ]
                [ text (toString gridWidth ++ "×" ++ toString gridHeight)
                ]
            , button
                [ type_ "button"
                , class "Sizer-button"
                , title "Drag to resize the grid"
                , style buttonStyles
                , onMouseDown MouseDown
                ]
                []
            ]


viewMinesInfo : Int -> Html Msg
viewMinesInfo numMines =
    let
        absoluteMaxNumMines =
            Helpers.maxNumMines Constants.maxWidth Constants.maxHeight

        maxWidth =
            absoluteMaxNumMines |> toString |> String.length

        styles =
            [ ( "box-sizing", "content-box" )
            , ( "width", toString maxWidth ++ "ch" )
            ]
    in
        div [ class "MinesInfo" ]
            [ text "0 / "
            , input
                [ type_ "tel"
                , value (toString numMines)
                , onChange NumMinesChange
                , style styles
                ]
                []
            ]
