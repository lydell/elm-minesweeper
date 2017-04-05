module Styles.Grid exposing (snippets)

import Css exposing (..)
import Css.Elements exposing (td)
import Styles.Classes exposing (Class(..))
import Styles.Colors as Colors


size : Em
size =
    em 1


snippets : List Snippet
snippets =
    [ class Grid
        [ property "table-layout" "fixed"
        , property "border-spacing" "0"
        , border3 (px 1) solid (hex Colors.greyLando)
        , padding (px 1)
        , backgroundColor (hex Colors.white)
        , cursor default
        , overflow hidden
        , descendants
            [ td
                [ width size
                , height size
                , padding zero
                ]
            ]
        , focus
            [ outline none
            , borderColor (hex Colors.blue)
            ]
        , withClass Is_focusWithin
            [ borderColor (hex Colors.blue)
            ]
        ]
    ]
