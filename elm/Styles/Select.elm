module Styles.Select exposing (snippets)

import Css exposing (..)
import Styles.Classes exposing (Class(..))
import Styles.Colors as Colors


snippets : List Snippet
snippets =
    [ class Select
        [ property "-webkit-appearance" "none"
        , property "-moz-appearance" "none"
        , property "appearance" "none"
        , boxSizing contentBox
        , width (ch 2.5)
        , margin zero
        , padding (em 0.1)
        , paddingRight (em 0.9)
        , border3 (px 1) solid (hex Colors.greyLando)
        , borderRadius zero
        , backgroundColor (hex Colors.white)
        , backgroundImage (url "data:image/svg+xml,%3C%3Fxml%20version%3D%221.0%22%20%3F%3E%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%2020.52%2010.88%22%3E%3Cpolygon%20points%3D%2220.52%202.31%2018.59%200%2010.26%206.97%201.93%200%200%202.31%2010.26%2010.88%2010.26%2010.88%2010.26%2010.88%2020.52%202.31%22%20fill%3D%22%23000%22%2F%3E%3C%2Fsvg%3E")
        , backgroundSize2 auto (em 0.25)
        , property "background-position" "right 0.25em center"
        , backgroundRepeat noRepeat
        , textAlign right
        , textAlignLast right
        , hover interaction
        , focus interaction
        , active interaction
        ]
    ]


interaction : List Mixin
interaction =
    [ outline none
    , borderColor (hex Colors.blue)
    ]
