module Styles.Global exposing (snippets)

import Css exposing (..)
import Css.Elements exposing (body, button, html, input, p, select, textarea)
import Styles.Colors as Colors


snippets : List Snippet
snippets =
    [ selector "*, *::before, *::after"
        [ boxSizing borderBox
        ]
    , html
        [ backgroundColor (hex Colors.greyLeia)
        , color (hex Colors.black)
        , property "font" "menu"
        , fontSize (px 20)
        , lineHeight (num 1.3)
        ]
    , body
        [ margin zero
        ]
    , p
        [ margin zero
        ]
    , each [ input, button, select, textarea ]
        [ fontFamily inherit
        , fontSize inherit
        , lineHeight inherit
        ]
    , each [ input, button ]
        [ pseudoElement "-moz-focus-inner"
            [ border zero
            , padding zero
            ]
        ]
    , select
        [ pseudoElement "-moz-focusring"
            [ color transparent
            , textShadow4 zero zero zero (hex Colors.black)
            ]
        ]
    ]
