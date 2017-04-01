module Types exposing (..)

import Dom
import Html exposing (Html)
import Html.Events.Custom exposing (KeyDetails)
import Matrix exposing (Matrix)
import Random.Pcg exposing (Seed)
import Window exposing (Size)


type alias Model =
    { debug : Bool
    , seed : Seed
    , grid : Matrix Cell
    , givenUp : Bool
    , selectedCell : Maybe ( Int, Int )
    , focus : Focus
    , windowSize : Size
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
    = FocusNone
    | FocusControls
    | FocusCell


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
    = WidthChange String
    | HeightChange String
    | NumMinesChange String
    | CellClick Int Int
    | CellRightClick Int Int
    | CellMouseEnter Int Int
    | CellMouseLeave Int Int
    | CellFocus Int Int
    | CellBlur Int Int
    | CellKeydown Int Int KeyDetails
    | GridKeydown KeyDetails
    | GiveUpButtonClick
    | PlayAgainButtonClick
    | FocusResult (Result Dom.Error ())
    | ControlsFocus
    | ControlsBlur
    | WindowSize Size
