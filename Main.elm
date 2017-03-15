module Main exposing (..)

import Helpers
import Html
import Matrix
import Random.Pcg as Random
import Types
    exposing
        ( Cell(Cell)
        , Flags
        , GameState(NewGame)
        , Grid
        , InnerCell(Hint, Mine)
        , Model
        , Msg(HeightInput, NumMinesInput, WidthInput)
        )
import View exposing (view)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }


init : Flags -> ( Model, Cmd msg )
init flags =
    let
        seed =
            Random.initialSeed flags.randomSeed

        numMines =
            5

        emptyGrid =
            Helpers.createEmptyGrid 9 9

        ( newSeed, grid ) =
            Helpers.addRandomMines numMines seed emptyGrid

        initialModel =
            { state = NewGame
            , seed = newSeed
            , numMines = numMines
            , grid = grid
            }
    in
        ( initialModel, Cmd.none )


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        WidthInput string ->
            let
                width =
                    Result.withDefault 0 (String.toInt string)
                        |> clamp Helpers.minWidth Helpers.maxWidth

                height =
                    Matrix.height model.grid

                grid =
                    Helpers.createEmptyGrid width height
            in
                ( { model | grid = grid }, Cmd.none )

        HeightInput string ->
            let
                width =
                    Matrix.width model.grid

                height =
                    Result.withDefault 0 (String.toInt string)
                        |> clamp Helpers.minHeight Helpers.maxHeight

                grid =
                    Helpers.createEmptyGrid width height
            in
                ( { model | grid = grid }, Cmd.none )

        NumMinesInput string ->
            let
                width =
                    Matrix.width model.grid

                height =
                    Matrix.height model.grid

                numMines =
                    Result.withDefault 0 (String.toInt string)
                        |> clamp Helpers.minNumMines (Helpers.maxNumMines width height)
            in
                ( { model | numMines = numMines }, Cmd.none )
