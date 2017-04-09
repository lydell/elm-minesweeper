module Styles.Controls exposing (snippets)

import Css exposing (..)
import Styles.Cell as Cell
import Styles.Classes exposing (Class(..))


{- TODO: Either find how, or refactor
   .Controls-inner > *:not(:first-child) {
     margin-left: 0.5em;
     min-height: 0;
   }

   .Controls-inner > *:nth-child(2):not(:last-child) {
     margin-left: auto;
   }
-}


snippets : List Snippet
snippets =
    [ class Controls
        [ paddingBottom (em 0.2) ]
    , class Controls_inner
        [ displayFlex
        , justifyContent spaceBetween
        , height (pct 100)
        , fontSize (em Cell.fontScale)
        , lineHeight (num 1)
        , children
            [ everything
                [ displayFlex
                ]
            ]
        ]
    , class Controls_emoji
        [ displayFlex
        , justifyContent center
        , alignItems center
        , fontSize (em 1.2)
        ]
    ]
