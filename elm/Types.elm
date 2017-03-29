module Types exposing (..)

import Dom
import Html exposing (Html)
import Matrix exposing (Matrix)
import Random.Pcg exposing (Seed)
import Window exposing (Size)


type alias Model =
    { debug : Bool
    , seed : Seed
    , numMines : Int
    , grid : Matrix Cell
    , givenUp : Bool
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
    | Hint Int


type alias CellContent =
    ( String, Html Msg )


type GridState
    = NewGrid
    | OngoingGrid
    | WonGrid
    | LostGrid
    | GivenUpGrid


type Msg
    = WidthChange String
    | HeightChange String
    | NumMinesChange String
    | CellClick Int Int
    | CellRightClick Int Int
    | GiveUpButtonClick
    | PlayAgainButtonClick
    | PlayAgainButtonFocus (Result Dom.Error ())
    | WindowSize Size
