module Styles.Controls exposing (snippets)

import Css exposing (..)
import Styles.Cell as Cell
import Styles.Classes exposing (Class(..))


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
                , adjacentSiblings
                    [ everything
                        [ marginLeft (em 0.5)
                        , minHeight zero
                        ]
                    ]
                ]
            ]
        ]
    , class Controls_spacer
        [ flex (int 1)
        ]
    , class Controls_emoji
        [ displayFlex
        , justifyContent center
        , alignItems center
        , fontSize (em 1.2)
        ]
    ]
