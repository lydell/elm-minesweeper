module View.Cell exposing (..)

import Dom
import Grid
import Html exposing (..)
import Html.Attributes exposing (attribute, id, style, type_)
import Html.Events exposing (onBlur, onClick, onFocus, onMouseEnter, onMouseLeave)
import Html.Events.Custom exposing (onKeydown, onRightClick)
import Styles.Classes as Classes exposing (class, classList)
import Styles.Colors as Colors
import Task
import Types exposing (..)
import View.Icon as Icon exposing (Icon)


numberColor : Int -> String
numberColor number =
    case number of
        1 ->
            Colors.blue

        2 ->
            Colors.green

        3 ->
            Colors.red

        4 ->
            Colors.purple

        5 ->
            Colors.brown

        6 ->
            Colors.mint

        7 ->
            Colors.black

        8 ->
            Colors.greyBoba

        _ ->
            "inherit"


mineIcon : Icon
mineIcon =
    Icon.new "💣"


flagIcon : Icon
flagIcon =
    Icon.new "🚩" |> Icon.color Colors.red


correctFlagIconHtml : Html Msg
correctFlagIconHtml =
    overlay (Icon.opacity 0.5 mineIcon) (Icon.opacity 0.5 flagIcon)


crossIcon : Icon
crossIcon =
    Icon.new "❌" |> Icon.color Colors.red


secret : CellContent
secret =
    ( "Secret", text "" )


hint : Int -> CellContent
hint number =
    ( toString number
    , strong
        [ style [ ( "color", numberColor number ) ] ]
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
    span [ class [ Classes.Cell_overlayContainer ] ]
        [ Icon.toHtml background
        , span [ class [ Classes.Cell_overlay ] ] [ Icon.toHtml foreground ]
        ]


cellId : Int -> Int -> Dom.Id
cellId x y =
    "cell-" ++ toString x ++ "-" ++ toString y


view : Bool -> Bool -> GameState -> Int -> Int -> Grid -> Html Msg
view debug isSelected gameState x y grid =
    let
        cell =
            Grid.get x y grid
                |> Maybe.withDefault Grid.defaultCell

        ( cellState, cellInner ) =
            case cell of
                Cell cellState_ cellInner_ ->
                    ( cellState_, cellInner_ )

        ( titleText_, display ) =
            content debug gameState x y grid

        classes =
            classList
                [ ( Classes.Cell, True )
                , ( Classes.Cell__unrevealed, cellState == Unrevealed )
                , ( Classes.Cell__revealedMine
                  , (cellState == Revealed)
                        && (cellInner == Mine)
                  )
                , ( Classes.Is_selected, isSelected )
                ]
    in
        button
            [ type_ "button"
            , id (cellId x y)
            , classes
            , attribute "aria-label" titleText_
            , onClick (Click_Cell x y)
            , onRightClick (RightClick_Cell x y)
            , onMouseEnter (MouseEnter_Cell x y)
            , onMouseLeave (MouseLeave_Cell x y)
            , onFocus (Focus_Cell x y)
            , onBlur (Blur_Cell x y)
            , onKeydown (Keydown_Cell x y)
            ]
            [ display ]


content : Bool -> GameState -> Int -> Int -> Grid -> CellContent
content debug gameState x y grid =
    case Grid.get x y grid of
        Just (Cell Flagged cellInner) ->
            if
                (gameState == WonGame)
                    || (gameState == LostGame)
                    || (gameState == GivenUpGame)
            then
                if cellInner == Mine then
                    correctFlag
                else
                    incorrectFlag
            else
                flag

        Just (Cell cellState Mine) ->
            if cellState == Revealed then
                detonatedMine
            else if gameState == WonGame then
                autoFlaggedMine
            else if
                (gameState == LostGame)
                    || (gameState == GivenUpGame)
                    || debug
            then
                mine
            else
                secret

        Just (Cell cellState Hint) ->
            let
                number =
                    Grid.cellNumber x y grid
            in
                if cellState == Revealed || debug then
                    if number == 0 then
                        secret
                    else
                        hint number
                else
                    secret

        Nothing ->
            secret


titleText : Bool -> GameState -> Int -> Int -> Grid -> String
titleText debug gameState x y grid =
    content debug gameState x y grid
        |> Tuple.first


focus : Int -> Int -> Cmd Msg
focus x y =
    Task.attempt FocusResult (Dom.focus (cellId x y))
