module Types exposing (..)

import Dom
import Html exposing (Html)
import Html.Events.Custom exposing (KeyDetails)
import Keyboard exposing (KeyCode)
import Matrix exposing (Matrix)
import Random.Pcg exposing (Seed)
import Window


type alias Model =
    { debug : Bool
    , seed : Seed
    , givenUp : Bool
    , grid : Grid
    , selectedCell : Maybe ( Int, Int )
    , helpVisible : Bool
    , focus : Focus
    , windowSize : Window.Size
    }


type alias LocalStorageModel =
    { givenUp : Bool
    , grid : Grid
    , selectedCell : Maybe ( Int, Int )
    }


type alias Grid =
    Matrix Cell


type Cell
    = Cell CellState CellInner


type CellState
    = Unrevealed
    | Revealed
    | Flagged


type CellInner
    = Mine
    | Hint


type alias CellContent =
    ( String, Html Msg )


type GameState
    = NewGame
    | OngoingGame
    | WonGame
    | LostGame
    | GivenUpGame


type Focus
    = NoFocus
    | ControlsFocus
    | CellFocus


type Movement
    = FixedMovement Int
    | EdgeMovement
    | SkipBlanksMovement


type Direction
    = Left
    | Right
    | Up
    | Down


type TabDirection
    = Forward
    | Backward


type Msg
    = Change_WidthSelect String
    | Change_HeightSelect String
    | Change_NumMinesInput String
    | Click_Cell Int Int
    | RightClick_Cell Int Int
    | MouseEnter_Cell Int Int
    | MouseLeave_Cell Int Int
    | Focus_Cell Int Int
    | Blur_Cell Int Int
    | Keydown_Cell Int Int KeyDetails
    | Keydown_Grid KeyDetails
    | Click_HelpButton
    | Click_GiveUpButton
    | Click_PlayAgainButton
    | FocusIn_Controls
    | FocusOut_Controls
    | Click_ModalBackdrop
    | Click_ModalCloseButton
    | Global_Keydown KeyCode
    | FocusResult (Result Dom.Error ())
    | WindowSize Window.Size
