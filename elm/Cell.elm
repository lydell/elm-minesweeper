module Cell exposing (..)

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


correctFlagIconHtml : Html Msg
correctFlagIconHtml =
    overlay (Icon.opacity 0.5 mineIcon) (Icon.opacity 0.5 flagIcon)


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
    ( "Correct flag", correctFlagIconHtml )


incorrectFlag : CellContent
incorrectFlag =
    ( "Incorrect flag", overlay flagIcon crossIcon )


mine : CellContent
mine =
    ( "Mine", Icon.toHtml mineIcon )


detonatedMine : CellContent
detonatedMine =
    ( "Detonated mine", Icon.toHtml mineIcon )


autoFlaggedMine : CellContent
autoFlaggedMine =
    ( "Automatically flagged mine", correctFlagIconHtml )


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
            not isGameEnd && (cellState == Unrevealed || cellState == Flagged)

        ( titleText, display ) =
            content debug gridState cell

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
    in
        if isClickable then
            button
                [ type_ "button"
                , titleAttribute
                , classes
                , onClick (CellClick x y)
                , onRightClick (CellRightClick x y)
                ]
                [ display ]
        else
            span
                [ titleAttribute
                , classes
                , attribute "oncontextmenu" "return false"
                ]
                [ display ]


content : Bool -> GridState -> Cell -> CellContent
content debug gridState cell =
    case cell of
        Cell Flagged cellInner ->
            if gridState == WonGrid || gridState == LostGrid then
                if cellInner == Mine then
                    correctFlag
                else
                    incorrectFlag
            else
                flag

        Cell cellState Mine ->
            if cellState == Revealed then
                detonatedMine
            else if gridState == WonGrid then
                autoFlaggedMine
            else if gridState == LostGrid || debug then
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
