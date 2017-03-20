module Cell exposing (..)

import Grid
import Html
    exposing
        ( Html
        , button
        , span
        , strong
        , text
        )
import Html.Attributes
    exposing
        ( attribute
        , class
        , classList
        , style
        , title
        , type_
        )
import Html.Events exposing (onClick)
import Html.Events.Custom exposing (onRightClick)
import Icon exposing (Icon)
import Types exposing (..)


numberColor : Int -> String
numberColor number =
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


mineIcon : Icon
mineIcon =
    Icon.new "💣"


flagIcon : Icon
flagIcon =
    Icon.new "🚩" |> Icon.color "#ff0000"


questionMarkIcon : Icon
questionMarkIcon =
    Icon.new "❓"


crossIcon : Icon
crossIcon =
    Icon.new "❌" |> Icon.color "#ff0000"


secret : CellContent
secret =
    ( "Secret", text "" )


hint : Int -> CellContent
hint number =
    ( toString number
    , strong
        [ style [ ( "color", numberColor number ) ]
        ]
        [ text (toString number) ]
    )


flag : CellContent
flag =
    ( "Flag", Icon.toHtml flagIcon )


correctFlag : CellContent
correctFlag =
    ( "Correct flag", overlay (Icon.opacity 0.5 mineIcon) flagIcon )


incorrectFlag : CellContent
incorrectFlag =
    ( "Incorrect flag", overlay flagIcon crossIcon )


questionMark : CellContent
questionMark =
    ( "Unsure", Icon.toHtml questionMarkIcon )


correctQuestionMark : CellContent
correctQuestionMark =
    ( "Correct question mark", overlay mineIcon questionMarkIcon )


inCorrectQuestionMark : CellContent
inCorrectQuestionMark =
    ( "Inorrect question mark", overlay questionMarkIcon crossIcon )


mine : CellContent
mine =
    ( "Mine", Icon.toHtml mineIcon )


detonatedMine : CellContent
detonatedMine =
    ( "Detonated mine", Icon.toHtml mineIcon )


overlay : Icon -> Icon -> Html Msg
overlay background foreground =
    span [ class "Cell-overlayContainer" ]
        [ Icon.toHtml background
        , span [ class "Cell-overlay" ] [ Icon.toHtml foreground ]
        ]


view : Bool -> GridState -> Int -> Int -> Cell -> Html Msg
view debug gridState x y ((Cell cellState cellInner) as cell) =
    let
        isGameEnd =
            gridState == WonGrid || gridState == LostGrid

        isClickable =
            not isGameEnd
                && (cellState == Unrevealed || cellState == Flagged || cellState == QuestionMarked)

        ( titleText, display ) =
            content debug isGameEnd cell

        useHoverTitle =
            not (cellState == Unrevealed || cellState == Revealed)
                || (cellInner == Mine)

        titleAttribute =
            if isGameEnd && useHoverTitle then
                title titleText
            else
                attribute "aria-label" titleText

        classes =
            classList
                [ ( "Cell", True )
                , ( "Cell--unrevealed", cellState == Unrevealed )
                , ( "Cell--revealedMine", cellState == Revealed && cellInner == Mine )
                ]

        size =
            toString Grid.cellSize ++ "px"

        styles =
            style
                [ ( "width", size )
                , ( "height", size )
                ]
    in
        if isClickable then
            button
                [ type_ "button"
                , titleAttribute
                , classes
                , styles
                , onClick (CellClick x y)
                , onRightClick (CellRightClick x y)
                ]
                [ display ]
        else
            span
                [ titleAttribute
                , classes
                , styles
                , attribute "oncontextmenu" "return false"
                ]
                [ display ]


content : Bool -> Bool -> Cell -> CellContent
content debug isGameEnd cell =
    case cell of
        Cell Flagged cellInner ->
            if isGameEnd then
                if cellInner == Mine then
                    correctFlag
                else
                    incorrectFlag
            else
                flag

        Cell QuestionMarked cellInner ->
            if isGameEnd then
                if cellInner == Mine then
                    correctQuestionMark
                else
                    inCorrectQuestionMark
            else
                questionMark

        Cell cellState Mine ->
            if cellState == Revealed then
                detonatedMine
            else if isGameEnd || debug then
                mine
            else
                secret

        Cell cellState (Hint number) ->
            if cellState == Revealed || debug then
                if number == 0 then
                    secret
                else
                    hint number
            else
                secret
