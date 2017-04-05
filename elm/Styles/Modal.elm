module Styles.Modal exposing (snippets)

import Css exposing (..)
import Css.Elements exposing (h1, h2)
import Styles.Classes exposing (Class(..))
import Styles.Colors as Colors


snippets : List Snippet
snippets =
    [ class Modal
        [ position fixed
        , zIndex (int 100)
        , top zero
        , bottom zero
        , left zero
        , right zero
        , displayFlex
        , justifyContent flexEnd
        , alignItems center
        , paddingRight (vh 6)
        , opacity zero
        , property "pointer-events" "none"
        , property "transition" "opacity 400ms"
        , withClass Is_visible
            [ opacity (int 1)
            , property "pointer-events" "auto"
            ]
        , focus
            [ outline none
            ]
        ]
    , mediaQuery "(max-width: 700px)"
        [ class Modal
            [ justifyContent center
            , padding2 zero (px 15)
            ]
        ]
    , class Modal_backdrop
        [ position absolute
        , zIndex (int -1)
        , top zero
        , bottom zero
        , left zero
        , right zero
        , backgroundColor (rgba 0 0 0 0.3)
        ]
    , class Modal_inner
        [ position relative
        , backgroundColor (hex Colors.white)
        , boxShadow5 zero (px 3) (px 5) zero (rgba 0 0 0 0.4)
        , fontSize (Css.rem 1)
        ]
    , class Modal_closeButton
        [ position absolute
        , top (px 15)
        , right (px 15)
        ]
    , class Modal_scroll
        [ maxWidth (px 600)
        , maxHeight (vh 88)
        , overflowY auto
        ]
    , class Modal_content
        [ padding (px 15)
        , children
            [ everything
                [ margin zero
                , adjacentSiblings
                    [ everything
                        [ marginTop (em 0.5)
                        ]
                    ]
                ]
            ]
        , descendants
            [ h1
                [ fontSize (em 1.7)
                ]
            , h2
                [ marginTop (em 0.9)
                , fontSize (em 1.5)
                ]
            ]
        ]
    ]
