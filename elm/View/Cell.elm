module View.Cell exposing (..)

import Dom
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


view : Bool -> Bool -> Bool -> Int -> Int -> Grid -> Html Msg
view debug givenUp isSelected x y grid =
    let
        cell =
            Grid.get x y grid
                |> Maybe.withDefault Grid.defaultCell

        ( cellState, cellInner ) =
            case cell of
                Cell cellState cellInner ->
                    ( cellState, cellInner )

        ( titleText_, display ) =
            content debug givenUp x y grid

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
            , attribute "aria-label" titleText_
            , onClick (CellClick x y)
            , onRightClick (CellRightClick x y)
            , onMouseEnter (CellMouseEnter x y)
            , onMouseLeave (CellMouseLeave x y)
            , onFocus (CellFocus x y)
            , onBlur (CellBlur x y)
            , onKeydown (CellKeydown x y)
            ]
            [ display ]


content : Bool -> Bool -> Int -> Int -> Grid -> CellContent
content debug givenUp x y grid =
    let
        gameState =
            Grid.gameState givenUp grid
    in
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
                else if gameState == LostGame || gameState == GivenUpGame || debug then
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


titleText : Bool -> Bool -> Int -> Int -> Grid -> String
titleText debug givenUp x y grid =
    content debug givenUp x y grid
        |> Tuple.first


focus : Int -> Int -> Cmd Msg
focus x y =
    Task.attempt FocusResult (Dom.focus (cellId x y))
