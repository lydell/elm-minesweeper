module Styles.Button exposing (snippets)

import Css exposing (..)
import Styles.Cell as Cell
import Styles.Classes exposing (Class(..))
import Styles.Colors as Colors


regularBackgroundColor : String
regularBackgroundColor =
    Colors.greyLuke


iconSize : String
iconSize =
    "calc(1em / " ++ toString Cell.fontScale ++ " + 4px)"


snippets : List Snippet
snippets =
    [ class Button
        [ margin zero
        , padding2 (em 0.1) (em 1)
        , border3 (px 1) solid (hex Colors.greyLando)
        , borderRadius zero
        , backgroundColor (hex regularBackgroundColor)
        , boxShadow6 inset zero zero zero (px 2) (hex Colors.white)
        , hover interaction
        , focus interaction
        , active interaction
        ]
    , class Button__muted
        [ fontSize (em 0.5)
        , backgroundColor transparent
        ]
    , class Button__icon
        [ displayFlex
        , justifyContent center
        , alignItems center
        , property "width" iconSize
        , property "min-height" iconSize
        , padding zero
        , fontSize (em 1)
        ]
    ]


interaction : List Mixin
interaction =
    [ outline none
    , borderColor (hex Colors.blue)
    , backgroundColor (hex regularBackgroundColor)
    ]
