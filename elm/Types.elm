module Types exposing (..)

import Html exposing (Html)
import Html.Events.Custom exposing (Button, PointerPosition)
import Matrix exposing (Matrix)
import Random.Pcg exposing (Seed)


type alias Model =
    { debug : Bool
    , seed : Seed
    , numMines : Int
    , grid : Matrix Cell
    , sizer : Sizer
    , pointerPosition : Maybe PointerPosition
    }


type alias Grid =
    Matrix Cell


type Cell
    = Cell CellState CellInner


type CellState
    = Unrevealed
    | Revealed
    | Flagged
    | QuestionMarked


type CellInner
    = Mine
    | Hint Int


type alias CellContent =
    ( String, Html Msg, Bool )


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
    | MouseDown Button PointerPosition
    | MouseUp
    | MouseMove PointerPosition
    | CellClick Int Int
    | CellRightClick Int Int
    | GiveUpButtonClick
    | PlayAgainButtonClick
