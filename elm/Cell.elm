module Cell exposing (..)

import Dom
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
        , id
        , style
        , type_
        )
import Html.Events exposing (onBlur, onClick, onFocus, onMouseEnter, onMouseLeave)
import Html.Events.Custom exposing (onKeydown, onRightClick)
import Icon exposing (Icon)
import Task
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


cellId : Int -> Int -> Dom.Id
cellId x y =
    "cell-" ++ toString x ++ "-" ++ toString y


view : Bool -> Bool -> GridState -> Int -> Int -> Cell -> Html Msg
view debug isSelected gridState x y ((Cell cellState cellInner) as cell) =
    let
        ( titleText, display ) =
            content debug gridState cell

        classes =
            classList
                [ ( "Cell", True )
                , ( "Cell--unrevealed", cellState == Unrevealed )
                , ( "Cell--revealedMine", cellState == Revealed && cellInner == Mine )
                , ( "is-selected", isSelected )
                ]
    in
        button
            [ type_ "button"
            , id (cellId x y)
            , classes
            , attribute "aria-label" titleText
            , onClick (CellClick x y)
            , onRightClick (CellRightClick x y)
            , onMouseEnter (CellMouseEnter x y)
            , onMouseLeave (CellMouseLeave x y)
            , onFocus (CellFocus x y)
            , onBlur (CellBlur x y)
            , onKeydown (CellKeydown x y)
            ]
            [ display ]


content : Bool -> GridState -> Cell -> CellContent
content debug gridState cell =
    case cell of
        Cell Flagged cellInner ->
            if
                (gridState == WonGrid)
                    || (gridState == LostGrid)
                    || (gridState == GivenUpGrid)
            then
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
            else if gridState == LostGrid || gridState == GivenUpGrid || debug then
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


getTitleText : Bool -> GridState -> Cell -> String
getTitleText debug gridState cell =
    content debug gridState cell
        |> Tuple.first


focus : Int -> Int -> Cmd Msg
focus x y =
    Task.attempt FocusResult (Dom.focus (cellId x y))
