module Styles.Main exposing (stylesheet)

import Css exposing (Snippet, Stylesheet)
import Css.Namespace
import Styles.Cell as Cell
import Styles.Classes
import Styles.Controls as Controls
import Styles.Global as Global
import Styles.Grid as Grid
import Styles.MultiplicationSign as MultiplicationSign
import Styles.Root as Root


allSnippets : List Snippet
allSnippets =
    Global.snippets
        ++ Cell.snippets
        ++ Controls.snippets
        ++ Grid.snippets
        ++ MultiplicationSign.snippets
        ++ Root.snippets


stylesheet : Stylesheet
stylesheet =
    allSnippets
        |> Css.Namespace.namespace Styles.Classes.namespace
        |> Css.stylesheet
