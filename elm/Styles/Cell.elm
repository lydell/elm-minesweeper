module Styles.Cell exposing (fontScale, snippets)

import Css exposing (..)
import Styles.Classes exposing (Class(..))
import Styles.Colors as Colors


fontScale : Float
fontScale =
    0.7


snippets : List Snippet
snippets =
    [ class Cell
        [ displayFlex
        , justifyContent center
        , alignItems center
        , width (pct 100)
        , height (pct 100)
        , margin zero
        , padding (px 1)
        , border zero
        , borderRadius zero
        , backgroundColor transparent
        , backgroundClip contentBox
        , fontWeight normal
        , fontSize (em fontScale)
        , lineHeight (int 1)
        , textAlign center
        , verticalAlign top
        , position relative
        , hover interaction
        , focus interaction
        , active interaction
        , withClass Is_selected
            [ before (circle "0" [])
            , after (circle "calc(-100% + 1px)" [ opacity (num 0.25) ])
            ]
        ]
    , class Cell__unrevealed
        [ backgroundColor (hex Colors.greyLuke)
        , active
            [ backgroundColor (hex Colors.greyWampa)
            ]
        ]
    , class Cell__revealedMine
        [ textShadow4 zero zero (em 0.5) (hex Colors.red) ]
    , class Cell_overlayContainer
        [ alignSelf flexEnd
        , marginLeft auto
        ]
    , class Cell_overlay
        [ position absolute
        , zIndex (int 1)
        , top zero
        , left zero
        ]
    ]


interaction : List Mixin
interaction =
    [ outline none
    ]


circle : String -> List Mixin -> List Mixin
circle distance extra =
    [ property "content" (qt "")
    , position absolute
    , zIndex (int 1)
    , property "top" distance
    , property "bottom" distance
    , property "left" distance
    , property "right" distance
    , border3 (px 1) solid (hex Colors.blue)
    , borderRadius (pct 50)
    , property "pointer-events" "none"
    ]
        ++ extra
