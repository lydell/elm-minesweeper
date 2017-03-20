module View exposing (view)

import Array
import Cell
import Grid
import Html
    exposing
        ( Html
        , button
        , div
        , input
        , p
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
            case viewBottomButton gridState of
                Just content ->
                    let
                        styles =
                            [ ( "margin-top", toString Grid.sizerOffset ++ "px" )
                            ]
                    in
                        [ div [ style styles ] [ content ] ]

                Nothing ->
                    []
    in
        div ([ classes ] ++ events)
            ([ viewMinesInfo model.numMines model.grid
             , div [ class "GridContainer" ]
                ([ viewGrid model.debug model.grid ] ++ sizer)
             ]
                ++ bottom
            )


viewGrid : Bool -> Grid -> Html Msg
viewGrid debug grid =
    table [ class "Grid" ]
        [ tbody []
            (List.indexedMap
                (viewRow debug (Grid.gridState grid))
                (Matrix.Custom.toListOfLists grid)
            )
        ]


viewRow : Bool -> GridState -> Int -> List Cell -> Html Msg
viewRow debug gridState y row =
    tr []
        (List.indexedMap
            (\x cell -> viewCell debug gridState x y cell)
            row
        )


viewCell : Bool -> GridState -> Int -> Int -> Cell -> Html Msg
viewCell debug gridState x y cell =
    td [] [ Cell.view debug gridState x y cell ]


viewSizer : Grid -> Sizer -> Maybe PointerPosition -> Html Msg
viewSizer grid sizer maybePointerPosition =
    let
        isDragging =
            Grid.isDragging sizer

        gridWidth =
            Matrix.width grid

        gridHeight =
            Matrix.height grid

        ( width, height ) =
            case sizer of
                Dragging { width, height } ->
                    ( width, height )

                _ ->
                    ( gridWidth, gridHeight )

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

                OngoingGrid ->
                    viewMinesCount numMines grid

                WonGrid ->
                    viewGameEndMessage True

                LostGrid ->
                    viewGameEndMessage False

        styles =
            [ ( "margin-bottom", toString Grid.sizerOffset ++ "px" )
            ]
    in
        div [ class "MinesInfo", style styles ] [ content ]


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
        p [ class "MinesInfo-text", title "Number of mines left to mark" ]
            [ text (toString count) ]


viewGameEndMessage : Bool -> Html Msg
viewGameEndMessage won =
    let
        ( titleText, emoji ) =
            if won then
                ( "You won!", "🎉" )
            else
                ( "You lost!", "☢️" )
    in
        p [ class "MinesInfo-text MinesInfo-text--emoji", title titleText ]
            [ text emoji ]


viewBottomButton : GridState -> Maybe (Html Msg)
viewBottomButton gridState =
    case gridState of
        NewGrid ->
            Nothing

        OngoingGrid ->
            Just giveUpButton

        WonGrid ->
            Just playAgainButton

        LostGrid ->
            Just playAgainButton


giveUpButton : Html Msg
giveUpButton =
    button
        [ type_ "button"
        , class "BottomButton"
        , onClick GiveUpButtonClick
        ]
        [ text "I give up!" ]


playAgainButton : Html Msg
playAgainButton =
    button
        [ type_ "button"
        , class "BottomButton"
        , onClick PlayAgainButtonClick
        ]
        [ text "Play again" ]
