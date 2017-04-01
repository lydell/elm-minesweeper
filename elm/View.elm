module View
    exposing
        ( view
        , focusGrid
        , focusControls
        , focusPlayAgainButton
        )

import Array
import Dom
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
        , id
        , selected
        , style
        , title
        , tabindex
        , type_
        , value
        )
import Html.Events exposing (onClick)
import Html.Events.Custom exposing (onChange, onFocusIn, onFocusOut, onKeydown)
import Icon
import Matrix
import Matrix.Custom
import Task
import Types exposing (..)


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


giveUpButtonId : Dom.Id
giveUpButtonId =
    "giveUpButtonId"


playAgainButtonId : Dom.Id
playAgainButtonId =
    "playAgainButton"


gridId : Dom.Id
gridId =
    "grid"


widthSelectId : Dom.Id
widthSelectId =
    "widthInput"


heightSelectId : Dom.Id
heightSelectId =
    "heightInput"


minesInputId : Dom.Id
minesInputId =
    "minesInput"


view : Model -> Html Msg
view model =
    let
        styles =
            [ ( "font-size", toString (fontSize model) ++ "px" )
            ]
    in
        div [ class "Root", style styles ]
            [ div []
                [ viewControls model
                , viewGrid model
                ]
            ]


viewGrid : Model -> Html Msg
viewGrid model =
    let
        gridState =
            Grid.gridState model.givenUp model.grid

        maybeCellWithCoords =
            Maybe.andThen
                (\( x, y ) ->
                    Matrix.get x y model.grid
                        |> Maybe.map ((,) ( x, y ))
                )
                model.selectedCell

        tooltip =
            case maybeCellWithCoords of
                Just ( ( x, y ), Cell cellState cellInner ) ->
                    let
                        isInteresting =
                            not (cellState == Unrevealed || cellState == Revealed)
                                || (cellInner == Mine)

                        titleText =
                            Cell.titleText model.debug
                                model.givenUp
                                x
                                y
                                model.grid
                    in
                        [ viewTooltip
                            (Grid.isGameEnd gridState && isInteresting)
                            x
                            y
                            model
                            titleText
                        ]

                Nothing ->
                    []
    in
        div [ class "GridContainer" ]
            ([ table
                [ class "Grid"
                , id gridId
                , tabindex -1
                , onKeydown GridKeydown
                ]
                [ tbody []
                    (List.indexedMap
                        (viewRow model)
                        (Matrix.Custom.toListOfLists model.grid)
                    )
                ]
             ]
                ++ tooltip
            )


viewRow : Model -> Int -> List Cell -> Html Msg
viewRow model y row =
    tr []
        (List.indexedMap
            (\x _ -> viewCell model x y)
            row
        )


viewCell : Model -> Int -> Int -> Html Msg
viewCell model x y =
    let
        isSelected =
            case model.selectedCell of
                Just ( selectedX, selectedY ) ->
                    x == selectedX && y == selectedY

                Nothing ->
                    False
    in
        td [] [ Cell.view model.debug model.givenUp isSelected x y model.grid ]


viewTooltip : Bool -> Int -> Int -> Model -> String -> Html Msg
viewTooltip visible x y model titleText =
    let
        classes =
            classList
                [ ( "GridContainer-tooltip", True )
                , ( "is-visible", visible )
                ]

        fontSizeNum =
            fontSize model

        ( offset, translateX, origin ) =
            if x <= Matrix.width model.grid // 2 then
                ( 0, "0%", "left" )
            else
                ( 1, "-100%", "right" )

        top =
            y * fontSizeNum

        left =
            toFloat (x + offset) * toFloat fontSizeNum

        styles =
            [ ( "top", toString top ++ "px" )
            , ( "left", toString left ++ "px" )
            , ( "transform", "translate(" ++ translateX ++ ", -100%) scale(0.4)" )
            , ( "transform-origin", origin ++ " bottom" )
            ]
    in
        span [ classes, style styles ]
            [ text titleText ]


viewControls : Model -> Html Msg
viewControls model =
    let
        ( leftContent, rightContent ) =
            case Grid.gridState model.givenUp model.grid of
                NewGrid ->
                    ( sizeControls model.grid
                    , viewMinesInput (Grid.numMines model.grid)
                    )

                OngoingGrid ->
                    ( giveUpButton, viewMinesCount model.grid )

                gridState ->
                    ( playAgainButton, viewGameEndMessage gridState )

        styles =
            [ ( "height", toString controlsHeight ++ "em" )
            ]
    in
        div
            [ class "Controls"
            , style styles
            , onFocusIn ControlsFocus
            , onFocusOut ControlsBlur
            ]
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
                , id minesInputId
                , class "InputWithIcon-input"
                , style styles
                ]
                []
            , span [ class "InputWithIcon-icon" ]
                [ Icon.toHtml Cell.mineIcon ]
            ]


viewMinesCount : Grid -> Html Msg
viewMinesCount grid =
    let
        numMines =
            Grid.numMines grid

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
            widthSelectId
            Grid.minWidth
            Grid.maxWidth
            (Matrix.width grid)
            WidthChange
        , span [ class "MultiplicationSign" ]
            [ text "×" ]
        , sizeSelect
            "Grid height"
            heightSelectId
            Grid.minHeight
            Grid.maxHeight
            (Matrix.height grid)
            HeightChange
        ]


sizeSelect : String -> Dom.Id -> Int -> Int -> Int -> (String -> msg) -> Html msg
sizeSelect titleString idString minSize maxSize currentSize msg =
    let
        options =
            List.range minSize maxSize
                |> List.map (sizeOption currentSize)
    in
        select
            [ class "Select"
            , id idString
            , title titleString
            , onChange msg
            ]
            options


sizeOption : Int -> Int -> Html msg
sizeOption currentSize size =
    option [ value (toString size), selected (size == currentSize) ] [ text (toString size) ]


giveUpButton : Html Msg
giveUpButton =
    button
        [ type_ "button"
        , id giveUpButtonId
        , class "Button Button--muted"
        , onClick GiveUpButtonClick
        ]
        [ text "I give up!" ]


playAgainButton : Html Msg
playAgainButton =
    button
        [ type_ "button"
        , id playAgainButtonId
        , class "Button"
        , onClick PlayAgainButtonClick
        ]
        [ text "Play again" ]


focusPlayAgainButton : Cmd Msg
focusPlayAgainButton =
    Task.attempt FocusResult (Dom.focus playAgainButtonId)


focusControls : TabDirection -> Cmd Msg
focusControls direction =
    let
        controlId =
            case direction of
                Forward ->
                    widthSelectId

                Backward ->
                    minesInputId
    in
        Dom.focus giveUpButtonId
            |> Task.onError (always (Dom.focus playAgainButtonId))
            |> Task.onError (always (Dom.focus controlId))
            |> Task.attempt FocusResult


focusGrid : Cmd Msg
focusGrid =
    Task.attempt FocusResult (Dom.focus gridId)
