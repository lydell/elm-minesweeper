module MyCss exposing (..)

import Css exposing (..)
import Css.Elements exposing (body, li, td)
import Css.Namespace


type CssClasses
    = Grid


type CssIds
    = Page


namespace : String
namespace =
    "MineSweeper"


css : Stylesheet
css =
    (stylesheet << Css.Namespace.namespace namespace)
        [ body
            [ margin (px 0)
            , backgroundColor (rgb 255 0 0)
            ]
        , class Grid
            [ descendants
                [ td
                    [ width (em 1)
                    , height (em 1)
                    , padding (px 0)
                    ]
                ]
            ]
        ]



-- css : Stylesheet
-- css =
--     stylesheet
--         [ body
--             [ overflowX auto
--             , minWidth (px 1280)
--             ]
--         , id Page
--             [ backgroundColor (rgb 200 128 64)
--             , color (hex "CCFFFF")
--             , width (pct 100)
--             , height (pct 100)
--             , boxSizing borderBox
--             , padding (px 8)
--             , margin zero
--             ]
--         , class NavBar
--             [ margin zero
--             , padding zero
--             , children
--                 [ li
--                     [ (display inlineBlock) |> important
--                     , color primaryAccentColor
--                     ]
--                 ]
--             ]
--         ]
--
--
-- primaryAccentColor =
--     hex "ccffaa"
