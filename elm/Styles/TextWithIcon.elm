module Styles.TextWithIcon exposing (snippets)

import Css exposing (..)
import Styles.Classes exposing (Class(..))
import Styles.Colors as Colors


snippets : List Snippet
snippets =
    [ class TextWithIcon
        [ displayFlex
        , margin zero
        , cursor text
        , position relative
        ]
    , class TextWithIcon_text
        [ displayFlex
        , alignItems center
        , margin zero
        , padding (em 0.1)
        , paddingLeft (em 0.15)
        , property "padding-right" "calc(0.4em + 1.5ch)"
        , border3 (px 1) solid transparent
        , borderRadius zero
        , textAlign right
        , fontWeight bold
        , cursor default
        ]
    , class TextWithIcon_text__input
        [ borderColor (hex Colors.greyLando)
        , backgroundColor (hex Colors.white)
        , cursor text
        , hover interaction
        , focus interaction
        , active interaction
        ]
    , class TextWithIcon_icon
        [ displayFlex
        , justifyContent center
        , alignItems center
        , position absolute
        , top zero
        , bottom zero
        , right (em 0.2)
        ]
    ]


interaction : List Mixin
interaction =
    [ outline none
    , borderColor (hex Colors.blue)
    ]
