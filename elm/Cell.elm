module Cell exposing (..)

import Grid
import Html
    exposing
        ( Html
        , button
        , span
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
import Types exposing (..)


mineEmoji : String
mineEmoji =
    "💣"


flagEmoji : String
flagEmoji =
    "🚩"


questionMarkEmoji : String
questionMarkEmoji =
    "❓"


whiteQuestionMarkEmoji : String
whiteQuestionMarkEmoji =
    "❔"


crossEmoji : String
crossEmoji =
    "❌"


secret : CellContent
secret =
    ( "Secret", text "", False )


hint : Int -> CellContent
hint number =
    ( toString number, text (toString number), False )


flag : CellContent
flag =
    ( "Flag", text flagEmoji, True )


correctFlag : CellContent
correctFlag =
    ( "Correct flag"
    , span []
        [ text mineEmoji
        , span [ class "Cell-overlay" ] [ text flagEmoji ]
        ]
    , True
    )


incorrectFlag : CellContent
incorrectFlag =
    ( "Incorrect flag"
    , span []
        [ text mineEmoji
        , span [ class "Cell-overlay" ] [ text crossEmoji ]
        ]
    , True
    )


questionMark : CellContent
questionMark =
    ( "Unsure", text questionMarkEmoji, True )


correctQuestionMark : CellContent
correctQuestionMark =
    ( "Correct question mark"
    , span []
        [ text mineEmoji
        , span [ class "Cell-overlay" ] [ text whiteQuestionMarkEmoji ]
        ]
    , True
    )


inCorrectQuestionMark : CellContent
inCorrectQuestionMark =
    ( "Inorrect question mark", text whiteQuestionMarkEmoji, True )


mine : CellContent
mine =
    ( "Mine", text mineEmoji, True )


detonatedMine : CellContent
detonatedMine =
    ( "Detonated mine", text mineEmoji, True )


view : Bool -> GridState -> Int -> Int -> Cell -> Html Msg
view debug gridState x y ((Cell cellState cellInner) as cell) =
    let
        isGameEnd =
            gridState == WonGrid || gridState == LostGrid

        isClickable =
            (gridState == NewGrid || gridState == OngoingGrid)
                && (cellState == Unrevealed || cellState == Flagged || cellState == QuestionMarked)

        ( titleText, display, isEmoji ) =
            content debug isGameEnd cell

        titleAttribute =
            if isGameEnd then
                title titleText
            else
                attribute "aria-label" titleText

        classes =
            classList
                [ ( "Cell", True )
                , ( "Cell--emoji", isEmoji )
                , ( "Cell--unrevealed", cellState == Unrevealed )
                , ( "Cell--revealedMine", cellState == Revealed && cellInner == Mine )
                ]

        size =
            toString Grid.cellSize ++ "px"

        styles =
            style
                [ ( "width", size )
                , ( "height", size )
                , ( "color", color cell )
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
            span [ titleAttribute, classes, styles ] [ display ]


color : Cell -> String
color cell =
    case cell of
        Cell Flagged _ ->
            "#ff0000"

        Cell QuestionMarked _ ->
            "inherit"

        Cell _ (Hint number) ->
            numberColor number

        _ ->
            "inherit"


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


content : Bool -> Bool -> Cell -> ( String, Html Msg, Bool )
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
