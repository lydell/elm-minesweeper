module View exposing (focusControls, focusGrid, focusPlayAgainButton, view)

import Dom
import Grid
import Html exposing (Html, button, div, input, label, option, p, select, span, table, tbody, td, text, tr)
import Html.Attributes exposing (attribute, class, classList, id, selected, style, title, tabindex, type_, value)
import Html.Custom exposing (none)
import Html.Events exposing (onClick)
import Html.Events.Custom exposing (onChange, onFocusIn, onFocusOut, onKeydown)
import Html.Lazy exposing (lazy)
import Task
import Types exposing (..)
import View.Cell as Cell
import View.HelpModal as HelpModal
import View.Icon as Icon
import Window


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


fontSize : Grid -> Window.Size -> Int
fontSize grid windowSize =
    let
        gridWidth =
            Grid.width grid

        gridHeight =
            Grid.height grid

        maxWidth =
            (windowSize.width - gridMargin * 2) // gridWidth

        maxHeight =
            toFloat (windowSize.height - gridMargin * 2)
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
        fontSizeNum =
            fontSize model.grid model.windowSize

        styles =
            [ ( "font-size", toString fontSizeNum ++ "px" )
            ]

        -- `gameState` is expensive to calculate, so it is calculated once here
        -- at the top and passed down instead of letting functions calculate it
        -- on their own.
        gameState =
            Grid.gameState model.givenUp model.grid
    in
        div [ class "Root", style styles ]
            [ div []
                [ controls model.grid gameState
                , viewGrid model gameState fontSizeNum
                ]
            , HelpModal.view model.helpVisible
            ]


viewGrid : Model -> GameState -> Int -> Html Msg
viewGrid model gameState fontSizeNum =
    let
        maybeCellWithCoords =
            Maybe.andThen
                (\( x, y ) ->
                    Grid.get x y model.grid
                        |> Maybe.map ((,) ( x, y ))
                )
                model.selectedCell

        tooltip_ =
            case maybeCellWithCoords of
                Just ( ( x, y ), Cell cellState cellInner ) ->
                    let
                        isInteresting =
                            cellState == Flagged || cellInner == Mine

                        titleText =
                            Cell.titleText model.debug
                                model.givenUp
                                gameState
                                x
                                y
                                model.grid
                    in
                        tooltip
                            (Grid.isGameEnd gameState && isInteresting)
                            (Grid.width model.grid)
                            fontSizeNum
                            x
                            y
                            titleText

                Nothing ->
                    none

        classes =
            classList
                [ ( "Grid", True )
                , ( "is-focusWithin", model.focus == CellFocus )
                ]
    in
        div [ class "GridContainer" ]
            [ table
                [ classes
                , id gridId
                , tabindex -1
                , onKeydown Keydown_Grid
                ]
                [ tbody []
                    (List.indexedMap
                        (viewRow model gameState)
                        (Grid.toListOfLists model.grid)
                    )
                ]
            , tooltip_
            ]


viewRow : Model -> GameState -> Int -> List Cell -> Html Msg
viewRow model gameState y row =
    tr []
        (List.indexedMap
            (\x _ -> viewCell model gameState x y)
            row
        )


viewCell : Model -> GameState -> Int -> Int -> Html Msg
viewCell model gameState x y =
    let
        isSelected =
            case model.selectedCell of
                Just ( selectedX, selectedY ) ->
                    x == selectedX && y == selectedY

                Nothing ->
                    False
    in
        td []
            [ Cell.view
                model.debug
                model.givenUp
                isSelected
                gameState
                x
                y
                model.grid
            ]


tooltip : Bool -> Int -> Int -> Int -> Int -> String -> Html Msg
tooltip visible gridWidth fontSizeNum x y titleText =
    let
        classes =
            classList
                [ ( "GridContainer-tooltip", True )
                , ( "is-visible", visible )
                ]

        ( offset, translateX, origin ) =
            if x <= gridWidth // 2 then
                ( 0, "0%", "left" )
            else
                ( 1, "-100%", "right" )

        top =
            y * fontSizeNum

        left =
            toFloat (x + offset) * toFloat fontSizeNum

        transform =
            "translate(" ++ translateX ++ ", -100%) scale(0.4)"

        styles =
            [ ( "top", toString top ++ "px" )
            , ( "left", toString left ++ "px" )
            , ( "transform", transform )
            , ( "transform-origin", origin ++ " bottom" )
            ]
    in
        span [ classes, style styles ]
            [ text titleText ]


controls : Grid -> GameState -> Html Msg
controls grid gameState =
    let
        ( leftContent, rightContent ) =
            case gameState of
                NewGame ->
                    -- `minesInput` has to be lazy because of `Keyboard.downs`.
                    ( sizeControls grid, lazy minesInput grid )

                OngoingGame ->
                    ( giveUpButton, minesCount grid )

                gameState_ ->
                    ( playAgainButton, gameEndMessage gameState_ )

        styles =
            [ ( "height", toString controlsHeight ++ "em" )
            ]

        helpButton_ =
            if Grid.isGameEnd gameState then
                none
            else
                helpButton (gameState == OngoingGame)
    in
        div
            [ class "Controls"
            , style styles
            , onFocusIn FocusIn_Controls
            , onFocusOut FocusOut_Controls
            ]
            [ div [ class "Controls-inner" ]
                [ leftContent
                , rightContent
                , helpButton_
                ]
            ]


minesInput : Grid -> Html Msg
minesInput grid =
    let
        numMines =
            Grid.numMines grid

        maxNumMines =
            Grid.maxNumMines (Grid.width grid) (Grid.height grid)

        maxWidth =
            maxNumMines |> toString |> String.length

        styles =
            [ ( "box-sizing", "content-box" )
            , ( "width", toString maxWidth ++ "ch" )
            ]
    in
        label [ class "TextWithIcon", title "Number of mines" ]
            [ input
                [ type_ "tel"
                , value (toString numMines)
                , onChange Change_NumMinesInput
                , id minesInputId
                , class "TextWithIcon-text TextWithIcon-text--input"
                , style styles
                ]
                []
            , span [ class "TextWithIcon-icon" ]
                [ Icon.toHtml Cell.mineIcon ]
            ]


minesCount : Grid -> Html Msg
minesCount grid =
    let
        count =
            (Grid.numMines grid) - (Grid.numFlags grid)
    in
        span [ class "TextWithIcon" ]
            [ span [ class "TextWithIcon-text" ]
                [ text (toString count) ]
            , span [ class "TextWithIcon-icon" ]
                [ Icon.toHtml Cell.mineIcon ]
            ]


gameEndMessage : GameState -> Html Msg
gameEndMessage gameState =
    let
        ( titleText, emoji ) =
            case gameState of
                WonGame ->
                    ( "You won!", "🎉" )

                LostGame ->
                    ( "You lost!", "☢️" )

                GivenUpGame ->
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
            (Grid.width grid)
            Change_WidthSelect
        , span [ class "MultiplicationSign" ]
            [ text "×" ]
        , sizeSelect
            "Grid height"
            heightSelectId
            Grid.minHeight
            Grid.maxHeight
            (Grid.height grid)
            Change_HeightSelect
        ]


sizeSelect :
    String
    -> Dom.Id
    -> Int
    -> Int
    -> Int
    -> (String -> msg)
    -> Html msg
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
    option [ value (toString size), selected (size == currentSize) ]
        [ text (toString size) ]


giveUpButton : Html Msg
giveUpButton =
    button
        [ type_ "button"
        , id giveUpButtonId
        , class "Button Button--muted"
        , onClick Click_GiveUpButton
        ]
        [ text "I give up!" ]


playAgainButton : Html Msg
playAgainButton =
    button
        [ type_ "button"
        , id playAgainButtonId
        , class "Button"
        , onClick Click_PlayAgainButton
        ]
        [ text "Play again" ]


helpButton : Bool -> Html Msg
helpButton muted =
    let
        classes =
            classList
                [ ( "Button", True )
                , ( "Button--icon", True )
                , ( "Button--muted", muted )
                ]
    in
        button
            [ type_ "button"
            , classes
            , onClick Click_HelpButton
            , title "Help"
            ]
            [ text "❓" ]


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


focusPlayAgainButton : Cmd Msg
focusPlayAgainButton =
    Task.attempt FocusResult (Dom.focus playAgainButtonId)
