module Types exposing (..)

import Html.Events.Custom exposing (PointerPosition)
import Matrix exposing (Matrix)
import Random.Pcg exposing (Seed)


type alias Model =
    { state : GameState
    , seed : Seed
    , numMines : Int
    , grid : Matrix Cell
    , sizer : Sizer
    , pointerPosition : Maybe PointerPosition
    }


type GameState
    = RegularGame
    | GivenUp


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
    | Hint Int


type GridState
    = NewGrid
    | OngoingGrid
    | WonGrid
    | LostGrid


type Sizer
    = Idle
    | Dragging DragStartData


type alias DragStartData =
    { pointerPosition : PointerPosition
    , width : Int
    , height : Int
    }


type alias PointerMovement =
    { dx : Int
    , dy : Int
    }


type Msg
    = NumMinesChange String
    | MouseDown PointerPosition
    | MouseUp
    | MouseMove PointerPosition
    | CellClick Int Int
