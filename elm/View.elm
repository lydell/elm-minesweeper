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
        , label
        , option
        , p
        , select
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
        , selected
        , style
        , title
        , type_
        , value
        )
import Html.Events exposing (onClick)
import Html.Events.Custom exposing (onChange)
import Icon
import Matrix
import Matrix.Custom
import Types exposing (..)


{-
   - mobile controls sizings and emoji
   - mobile icons
-}


controlsHeight : Float
controlsHeight =
    -- em
    1.3


gridMargin : Int
gridMargin =
    -- px
    8


maxFontSize : Int
maxFontSize =
    -- px
    48


fontSize : Model -> Int
fontSize model =
    let
        gridWidth =
            Matrix.width model.grid

        gridHeight =
            Matrix.height model.grid

        maxWidth =
            (model.windowSize.width - gridMargin * 2) // gridWidth

        maxHeight =
            toFloat (model.windowSize.height - gridMargin * 2)
                / (toFloat gridHeight + controlsHeight)
                |> floor
    in
        min maxWidth maxHeight
            |> min maxFontSize


view : Model -> Html Msg
view model =
    let
        styles =
            [ ( "font-size", toString (fontSize model) ++ "px" )
            ]
    in
        div [ class "Root", style styles ]
            [ div []
                [ viewControls model.givenUp model.numMines model.grid
                , viewGrid model.debug model.givenUp model.grid
                ]
            ]


viewGrid : Bool -> Bool -> Grid -> Html Msg
viewGrid debug givenUp grid =
    table [ class "Grid" ]
        [ tbody []
            (List.indexedMap
                (viewRow debug (Grid.gridState givenUp grid))
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


viewControls : Bool -> Int -> Grid -> Html Msg
viewControls givenUp numMines grid =
    let
        ( leftContent, rightContent ) =
            case Grid.gridState givenUp grid of
                NewGrid ->
                    ( sizeControls grid, viewMinesInput numMines )

                OngoingGrid ->
                    ( giveUpButton, viewMinesCount numMines grid )

                gridState ->
                    ( playAgainButton, viewGameEndMessage gridState )

        styles =
            [ ( "height", toString controlsHeight ++ "em" )
            ]
    in
        div [ class "Controls", style styles ]
            [ div [ class "Controls-inner" ]
                [ leftContent
                , rightContent
                ]
            ]


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
        label [ class "InputWithIcon", title "Number of mines" ]
            [ input
                [ type_ "tel"
                , value (toString numMines)
                , onChange NumMinesChange
                , class "InputWithIcon-input"
                , style styles
                ]
                []
            , span [ class "InputWithIcon-icon" ]
                [ Icon.toHtml Cell.mineIcon ]
            ]


viewMinesCount : Int -> Grid -> Html Msg
viewMinesCount numMines grid =
    let
        flagged =
            Matrix.filter Grid.isCellFlagged grid

        count =
            numMines - Array.length flagged
    in
        span [ class "TextWithIcon" ]
            [ span [ class "TextWithIcon-inner" ]
                [ span [ class "TextWithIcon-text" ]
                    [ text (toString count) ]
                , Icon.toHtml Cell.mineIcon
                ]
            ]


viewGameEndMessage : GridState -> Html Msg
viewGameEndMessage gridState =
    let
        ( titleText, emoji ) =
            case gridState of
                WonGrid ->
                    ( "You won!", "🎉" )

                LostGrid ->
                    ( "You lost!", "☢️" )

                GivenUpGrid ->
                    ( "You gave up!", "🏳" )

                _ ->
                    ( "You managed to break the game!", "❓" )
    in
        span [ class "Controls-emoji", title titleText ] [ text emoji ]


sizeControls : Grid -> Html Msg
sizeControls grid =
    span []
        [ sizeSelect
            "Grid width"
            Grid.minWidth
            Grid.maxWidth
            (Matrix.width grid)
            WidthChange
        , span [ class "MultiplicationSign" ]
            [ text "×" ]
        , sizeSelect
            "Grid height"
            Grid.minHeight
            Grid.maxHeight
            (Matrix.height grid)
            HeightChange
        ]


sizeSelect : String -> Int -> Int -> Int -> (String -> msg) -> Html msg
sizeSelect titleString minSize maxSize currentSize msg =
    let
        options =
            List.range minSize maxSize
                |> List.map (sizeOption currentSize)
    in
        select [ class "Select", title titleString, onChange msg ]
            options


sizeOption : Int -> Int -> Html msg
sizeOption currentSize size =
    option [ value (toString size), selected (size == currentSize) ] [ text (toString size) ]


giveUpButton : Html Msg
giveUpButton =
    button
        [ type_ "button"
        , class "Button Button--muted"
        , onClick GiveUpButtonClick
        ]
        [ text "I give up!" ]


playAgainButton : Html Msg
playAgainButton =
    button
        [ type_ "button"
        , class "Button"
        , onClick PlayAgainButtonClick
        ]
        [ text "Play again" ]
