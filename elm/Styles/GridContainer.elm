module Styles.GridContainer exposing (snippets)

import Css exposing (..)
import Styles.Classes exposing (Class(..))
import Styles.Colors as Colors


snippets : List Snippet
snippets =
    [ class GridContainer
        [ position relative
        ]
    , class GridContainer_tooltip
        [ position absolute
        , zIndex (int 1)
        , marginLeft (px 2)
        , padding2 (em 0.3) (em 0.5)
        , backgroundColor (rgba 0 0 0 0.75)
        , color (hex Colors.white)
        , whiteSpace noWrap
        , property "pointer-events" "none"
        , opacity (int 0)
        , property "transition" "opacity 0ms"
        , withClass Is_visible
            [ opacity (int 1)
            , property "transition-delay" "200ms"
            ]
        ]
    ]
