module Types exposing (..)

import Matrix exposing (Matrix)
import Random.Pcg exposing (Seed)


type alias Flags =
    { randomSeed : Int
    }



{-
   There are several states:

   1. New game.
      Shows grid and three inputs for width, height and mines.
      Changing width, height or mines insta-updates the grid.
      The mines aren't placed until you click the first cell.
      There can be (width * height - 1) mines.

   2. Ongoing game.
      Shows grid and "I give up" button.
      "I give up" advances to next state.

   3. Finished game.
      Shows read-only grid.
      There is also a "Play again button". It advances to state 1.
      Also store whether user gave up or won, and vary display on that.
-}


type alias Model =
    { state : GameState
    , seed : Seed
    , numMines : Int
    , grid : Matrix Cell
    , sizer : Sizer
    , pointerPosition : Maybe PointerPosition
    }


type GameState
    = NewGame
    | OngoingGame
    | FinishedGame Bool


type alias Grid =
    Matrix Cell


type Cell
    = Cell InnerCell CellData


type alias CellData =
    { revealed : Bool
    }


type InnerCell
    = Mine
    | Hint Int


type Sizer
    = Idle
    | Dragging DragStartData


type alias DragStartData =
    { pointerPosition : PointerPosition
    , width : Int
    , height : Int
    }


type alias PointerPosition =
    { screenX : Int
    , screenY : Int
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
