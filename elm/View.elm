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
import Html.Events exposing (onClick, onInput, onMouseUp)
import Matrix
import Types exposing (..)


view : Model -> Html Msg
view model =
    let
        gridState =
            Helpers.gridState model.grid

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
            , viewBottom gridState
            ]


viewGrid : Grid -> Html Msg
viewGrid grid =
    let
        gridState =
            Helpers.gridState grid

        styles =
            [ ( "border-spacing", (toString Constants.cellSpacing) ++ "px" ) ]
    in
        table [ class "Grid", style styles ]
            [ tbody []
                (List.indexedMap (viewRow gridState) (Helpers.matrixToListsOfLists grid))
            ]


viewRow : GridState -> Int -> List Cell -> Html Msg
viewRow gridState rowNum row =
    tr []
        (List.indexedMap
            (\columnNum cell -> viewCell gridState columnNum rowNum cell)
            row
        )


viewCell : GridState -> Int -> Int -> Cell -> Html Msg
viewCell gridState columnNum rowNum ((Cell _ cellState) as cell) =
    let
        isClickable =
            (gridState == NewGrid || gridState == OngoingGrid)
                && (cellState == Unrevealed || cellState == Flagged)

        size =
            (toString Constants.cellSize) ++ "px"

        classes =
            classList
                [ ( "Cell", True )
                , ( "Cell--revealed", cellState == Revealed )
                ]

        styles =
            style
                [ ( "width", size )
                , ( "height", size )
                ]

        textContent =
            text (Helpers.cellToString cell)

        innerElement =
            if isClickable then
                button
                    [ type_ "button"
                    , classes
                    , styles
                    , onClick (CellClick columnNum rowNum)
                    ]
                    [ textContent ]
            else
                span [ classes, styles ] [ textContent ]
    in
        td [] [ innerElement ]


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


viewBottom : GridState -> Html Msg
viewBottom gridState =
    let
        message =
            case gridState of
                NewGrid ->
                    "New game"

                OngoingGrid ->
                    "TODO give up"

                WonGrid ->
                    "You won!"

                LostGrid ->
                    "You lost!"
    in
        p [ class "Bottom" ] [ text message ]
