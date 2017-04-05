module Styles.Classes exposing (Class(..), class, classList, namespace)

import Html exposing (Attribute)
import Html.CssHelpers as CssHelpers exposing (Namespace)


type Class
    = Button
    | Button__icon
    | Button__muted
    | Cell
    | Cell__revealedMine
    | Cell__unrevealed
    | Cell_overlay
    | Cell_overlayContainer
    | Controls
    | Controls_emoji
    | Controls_inner
    | Controls_spacer
    | Grid
    | GridContainer
    | GridContainer_tooltip
    | Is_focusWithin
    | Is_selected
    | Is_visible
    | Modal
    | Modal_backdrop
    | Modal_closeButton
    | Modal_content
    | Modal_inner
    | Modal_scroll
    | MultiplicationSign
    | Root
    | Select
    | TextWithIcon
    | TextWithIcon_icon
    | TextWithIcon_text
    | TextWithIcon_text__input


namespace : String
namespace =
    "ms-"


helpers : Namespace String class id msg
helpers =
    CssHelpers.withNamespace namespace


class : List Class -> Attribute msg
class =
    helpers.class


classList : List ( Class, Bool ) -> Attribute msg
classList =
    helpers.classList
