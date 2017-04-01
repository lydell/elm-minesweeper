module View.HelpModal exposing (view, focus)

import Dom
import Html exposing (Html, button, div, h1, h2, li, p, strong, text, ul)
import Html.Attributes exposing (attribute, class, classList, id, style, title, tabindex, type_)
import Html.Events exposing (onClick)
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
                [ ( "Modal", True )
                , ( "is-visible", visible )
                ]
    in
        div
            [ classes
            , id idString
            , tabindex -1
            , attribute "aria-hidden" (toString (not visible))
            ]
            [ div [ class "Modal-backdrop", onClick Click_ModalBackdrop ] []
            , div [ class "Modal-inner" ]
                [ button
                    [ type_ "button"
                    , title "Close"
                    , class "Button Button--icon Modal-closeButton"
                    , onClick Click_ModalCloseButton
                    ]
                    [ text "❌" ]
                , div [ class "Modal-scroll" ]
                    [ div [ class "Modal-content" ]
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
        , p []
            [ text <|
                "Clicking (or tapping etc.) on a number surrounded by exactly "
                    ++ "that number of flags is a shortcut to reveal all other "
                    ++ "neighbors."
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
                [ text "Shift: Skip to closest unrevealed cell." ]
            , li []
                [ text "Ctrl: Skip to the edge of the grid." ]
            , li []
                [ text "Alt or Meta: Jump 4 steps." ]
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
