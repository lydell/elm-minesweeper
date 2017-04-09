module Styles.Classes exposing (Class(..), class, classList, namespace)

import Html exposing (Attribute)
import Html.CssHelpers as CssHelpers exposing (Namespace)


type Class
    = Button
    | Button__icon
    | Button__muted
    | Cell
    | Cell__unrevealed
    | Cell__revealedMine
    | Cell_overlayContainer
    | Cell_overlay
    | Controls
    | Controls_inner
    | Controls_emoji
    | Grid
    | GridContainer
    | GridContainer_tooltip
    | Is_focusWithin
    | Is_selected
    | Is_visible
    | MultiplicationSign
    | Root


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
