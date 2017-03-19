module View exposing (view)

import Array
import Grid
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
import Html.Events.Custom
    exposing
        ( onChange
        , onMouseDown
        , onMouseMove
        , PointerPosition
        )
import Matrix
import Matrix.Custom
import Types exposing (..)


view : Model -> Html Msg
view model =
    let
        gridState =
            Grid.gridState model.grid

        isDragging =
            Grid.isDragging model.sizer

        events =
            if isDragging then
                [ onMouseMove MouseMove, onMouseUp MouseUp ]
            else
                []

        classes =
            classList
                [ ( "Root", True )
                , ( "is-dragging", isDragging )
                ]

        sizer =
            if gridState == NewGrid then
                [ viewSizer model.grid model.sizer model.pointerPosition ]
            else
                []

        bottom =
            viewBottom gridState
    in
        div ([ classes ] ++ events)
            ([ viewMinesInfo model.numMines model.grid
             , div [ class "GridContainer" ]
                ([ viewGrid model.grid ] ++ sizer)
             ]
                ++ bottom
            )


viewGrid : Grid -> Html Msg
viewGrid grid =
    let
        gridState =
            Grid.gridState grid

        styles =
            [ ( "border-spacing", toString Grid.cellSpacing ++ "px" ) ]
    in
        table [ class "Grid", style styles ]
            [ tbody []
                (List.indexedMap
                    (viewRow gridState)
                    (Matrix.Custom.toListOfLists grid)
                )
            ]


viewRow : GridState -> Int -> List Cell -> Html Msg
viewRow gridState y row =
    tr []
        (List.indexedMap
            (\x cell -> viewCell gridState x y cell)
            row
        )


viewCell : GridState -> Int -> Int -> Cell -> Html Msg
viewCell gridState x y ((Cell cellState _) as cell) =
    let
        isClickable =
            (gridState == NewGrid || gridState == OngoingGrid)
                && (cellState == Unrevealed || cellState == Flagged)

        size =
            toString Grid.cellSize ++ "px"

        classes =
            classList
                [ ( "Cell", True )
                , ( "Cell--revealed", cellState == Revealed )
                ]

        styles =
            style
                [ ( "width", size )
                , ( "height", size )
                , ( "color", numberColor cell )
                ]

        textContent =
            text (Grid.cellToString cell)

        innerElement =
            if isClickable then
                button
                    [ type_ "button"
                    , classes
                    , styles
                    , onClick (CellClick x y)
                    ]
                    [ textContent ]
            else
                span [ classes, styles ] [ textContent ]
    in
        td [] [ innerElement ]


numberColor : Cell -> String
numberColor cell =
    case cell of
        Cell _ (Hint number) ->
            case number of
                1 ->
                    "#0000ff"

                2 ->
                    "#007b00"

                3 ->
                    "#ff0000"

                4 ->
                    "#00007b"

                5 ->
                    "#7b0000"

                6 ->
                    "#007b7b"

                7 ->
                    "#000000"

                8 ->
                    "#7b7b7b"

                _ ->
                    "inherit"

        _ ->
            "inherit"


viewSizer : Grid -> Sizer -> Maybe PointerPosition -> Html Msg
viewSizer grid sizer maybePointerPosition =
    let
        isDragging =
            Grid.isDragging sizer

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
            Grid.pointerMovement sizer maybePointerPosition

        newWidth =
            (Grid.sizerSize width + pointerMovement.dx)
                |> Grid.clampSizerWidth

        newHeight =
            (Grid.sizerSize height + pointerMovement.dy)
                |> Grid.clampSizerHeight

        styles =
            [ ( "top", toString -Grid.sizerOffset ++ "px" )
            , ( "width", toString newWidth ++ "px" )
            , ( "height", toString newHeight ++ "px" )
            ]

        dimensions =
            if isDragging then
                [ p [ class "Sizer-dimensions", attribute "aria-label" "Grid size" ]
                    [ text (toString gridWidth ++ "×" ++ toString gridHeight)
                    ]
                ]
            else
                []

        buttonSize =
            toString Grid.cellSize ++ "px"

        buttonStyles =
            [ ( "width", buttonSize )
            , ( "height", buttonSize )
            ]

        resizerButton =
            button
                [ type_ "button"
                , class "Sizer-button"
                , title "Drag to resize the grid"
                , style buttonStyles
                , onMouseDown MouseDown
                ]
                []
    in
        div [ class "Sizer", style styles ]
            (dimensions ++ [ resizerButton ])


viewMinesInfo : Int -> Grid -> Html Msg
viewMinesInfo numMines grid =
    let
        content =
            case Grid.gridState grid of
                NewGrid ->
                    viewMinesInput numMines

                _ ->
                    viewMinesCount numMines grid
    in
        div [ class "MinesInfo" ] [ content ]


viewMinesInput : Int -> Html Msg
viewMinesInput numMines =
    let
        absoluteMaxNumMines =
            Grid.maxNumMines Grid.maxWidth Grid.maxHeight

        maxWidth =
            absoluteMaxNumMines |> toString |> String.length

        styles =
            [ ( "box-sizing", "content-box" )
            , ( "width", toString maxWidth ++ "ch" )
            ]
    in
        input
            [ type_ "tel"
            , value (toString numMines)
            , title "Number of mines (click to edit)"
            , onChange NumMinesChange
            , class "MinesInfo-input"
            , style styles
            ]
            []


viewMinesCount : Int -> Grid -> Html Msg
viewMinesCount numMines grid =
    let
        flagged =
            Matrix.filter Grid.isCellFlagged grid

        count =
            numMines - Array.length flagged
    in
        p [ class "MinesInfo-count", title "Number of mines left to mark" ]
            [ text (toString count) ]


viewBottom : GridState -> List (Html Msg)
viewBottom gridState =
    let
        maybeMessage =
            case gridState of
                NewGrid ->
                    Nothing

                OngoingGrid ->
                    -- TODO: "I give up" button.
                    Nothing

                WonGrid ->
                    -- TODO: "Play again" button.
                    Just "You won!"

                LostGrid ->
                    -- TODO: "Play again" button.
                    Just "You lost!"
    in
        case maybeMessage of
            Just message ->
                [ p [ class "Bottom" ] [ text message ] ]

            Nothing ->
                []
