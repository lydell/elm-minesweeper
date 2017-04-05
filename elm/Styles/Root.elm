module Styles.Root exposing (snippets)

import Css exposing (..)
import Styles.Classes exposing (Class(..))


snippets : List Snippet
snippets =
    [ class Root
        [ minHeight (vh 100)
        , displayFlex
        , flexDirection column
        , justifyContent center
        , alignItems center
        , property "-webkit-user-select" "none"
        , property "-moz-user-select" "none"
        , property "-ms-user-select" "none"
        , property "user-select" "none"
        ]
    ]
