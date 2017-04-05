module Styles.MultiplicationSign exposing (snippets)

import Css exposing (..)
import Styles.Classes exposing (Class(..))


snippets : List Snippet
snippets =
    [ class MultiplicationSign
        [ displayFlex
        , justifyContent center
        , alignItems center
        , width (em 1)
        ]
    ]
