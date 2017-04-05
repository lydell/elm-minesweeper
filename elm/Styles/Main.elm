module Styles.Main exposing (stylesheet)

import Css exposing (Snippet, Stylesheet)
import Css.Namespace
import Styles.Button as Button
import Styles.Cell as Cell
import Styles.Classes
import Styles.Controls as Controls
import Styles.Global as Global
import Styles.Grid as Grid
import Styles.GridContainer as GridContainer
import Styles.Modal as Modal
import Styles.MultiplicationSign as MultiplicationSign
import Styles.Root as Root
import Styles.Select as Select
import Styles.TextWithIcon as TextWithIcon


allSnippets : List Snippet
allSnippets =
    Global.snippets
        ++ Button.snippets
        ++ Cell.snippets
        ++ Controls.snippets
        ++ Grid.snippets
        ++ GridContainer.snippets
        ++ Modal.snippets
        ++ MultiplicationSign.snippets
        ++ Root.snippets
        ++ Select.snippets
        ++ TextWithIcon.snippets


stylesheet : Stylesheet
stylesheet =
    allSnippets
        |> Css.Namespace.namespace Styles.Classes.namespace
        |> Css.stylesheet
