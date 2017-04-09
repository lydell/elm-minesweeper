module Styles.Button exposing (snippets)

import Css exposing (..)
import Styles.Classes exposing (Class(..))
import Styles.Colors as Colors


snippets : List Snippet
snippets =
    [ class Button
        [ margin zero
        , padding2 (em 0.1) (em 1)
        , border3 (px 1) solid (hex Colors.greyLando)
        , borderRadius zero
        , backgroundColor (hex Colors.greyLuke)
        , boxShadow6 inset zero zero zero (px 2) (hex Colors.white)
        ]
    ]
