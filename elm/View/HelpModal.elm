module View.HelpModal exposing (view, focus)

import Dom
import Html exposing (..)
import Html.Attributes exposing (attribute, id, style, title, tabindex, type_)
import Html.Events exposing (onClick)
import Styles.Classes as Classes exposing (class, classList)
import Task
import Types exposing (..)


helpModalId : Dom.Id
helpModalId =
    "helpModal"


modal : Bool -> String -> List (Html Msg) -> Html Msg
modal visible idString content =
    let
        classes =
            classList
                [ ( Classes.Modal, True )
                , ( Classes.Is_visible, visible )
                ]
    in
        div
            [ classes
            , id idString
            , tabindex -1
            , attribute "aria-hidden" (toString (not visible))
            ]
            [ div
                [ class [ Classes.Modal_backdrop ]
                , onClick Click_ModalBackdrop
                ]
                []
            , div [ class [ Classes.Modal_inner ] ]
                [ button
                    [ type_ "button"
                    , title "Close"
                    , class
                        [ Classes.Button
                        , Classes.Button__icon
                        , Classes.Modal_closeButton
                        ]
                    , onClick Click_ModalCloseButton
                    ]
                    [ text "❌" ]
                , div [ class [ Classes.Modal_scroll ] ]
                    [ div [ class [ Classes.Modal_content ] ]
                        content
                    ]
                ]
            ]


view : Bool -> Html Msg
view visible =
    modal visible
        helpModalId
        [ h1 []
            [ text "Minesweeper" ]
        , p []
            [ text
                "Behind each cell there is either a mine, a number or nothing."
            ]
        , ul []
            [ li []
                [ text "If you reveal a mine, you lose!" ]
            , li []
                [ text "A number shows how many of its neighbors are mines." ]
            , li []
                [ text <|
                    "Empty cells have no neighboring mines, so all their "
                        ++ "neighbors are revealed automatically."
                ]
            ]
        , p []
            [ text "When all mine-free cells are revealed you win!" ]
        , p []
            [ text
                "You can place flags to help remember where the mines must be."
            ]
        , h2 []
            [ text "Mouse" ]
        , action "Reveal" "Click."
        , action "Flag" "Right-click."
        , h2 []
            [ text "Touch" ]
        , action "Reveal" "Tap."
        , action "Flag" "Long-tap."
        , h2 []
            [ text "Keyboard" ]
        , action "Reveal" "Enter or Space."
        , action "Flag" "Backspace, Delete or any character."
        , action "Move around" "Arrow keys. Modifiers:"
        , ul []
            [ li []
                [ action "Shift" "Skip to closest unrevealed cell." ]
            , li []
                [ action "Ctrl" "Skip to the edge of the grid." ]
            , li []
                [ action "Alt or Meta" "Jump 4 steps." ]
            ]
        , h2 []
            [ text "Shortcuts" ]
        , p []
            [ text <|
                "Revaling and flagging on already revealed numbers operates "
                    ++ "on all unrevealed neighbors instead."
            ]
        , action "Reveal" "If surrounded by exactly that number of flags."
        , action "Flag" <|
            "If there is only one way to surround with exactly that number of "
                ++ "flags."
        , h2 []
            [ text "Increasing the difficulty" ]
        , p []
            [ text <|
                "Besides tweaking the size and the number of mines, here are "
                    ++ "a few tips for increasingly difficult game play:"
            ]
        , ol []
            [ li []
                [ text "Don’t use the auto-flag shortcut." ]
            , li []
                [ text "Don’t use the auto-reveal shortcut." ]
            , li []
                [ text "Don’t use any flags at all." ]
            ]
        ]


action : String -> String -> Html Msg
action actionName description =
    p []
        [ strong []
            [ text (actionName ++ ": ") ]
        , text description
        ]


focus : Cmd Msg
focus =
    Task.attempt FocusResult (Dom.focus helpModalId)
