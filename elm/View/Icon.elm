module View.Icon exposing (Icon, color, new, opacity, toHtml)

import Html exposing (..)
import Html.Attributes exposing (style)


type Icon
    = Icon { emoji : String, color : String, opacity : Float }


new : String -> Icon
new emoji =
    Icon { emoji = emoji, color = "inherit", opacity = 1 }


color : String -> Icon -> Icon
color colorString (Icon iconData) =
    Icon { iconData | color = colorString }


opacity : Float -> Icon -> Icon
opacity opacityFloat (Icon iconData) =
    Icon { iconData | opacity = opacityFloat }


toHtml : Icon -> Html msg
toHtml (Icon iconData) =
    let
        styles =
            [ ( "color", iconData.color )
            , ( "opacity", toString iconData.opacity )
            ]
    in
        span [ style styles ] [ text iconData.emoji ]
