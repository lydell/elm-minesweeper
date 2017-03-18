module Main exposing (..)

import Helpers
import Html
import Matrix
import Random.Pcg as Random
import Types exposing (..)
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
            10

        emptyGrid =
            Helpers.createEmptyGrid 9 9

        -- It is not needed to add mines and all at this point, but it makes
        -- debugging easier.
        ( newSeed, grid ) =
            Helpers.addRandomMinesAndUpdateNumbers numMines seed emptyGrid

        initialModel =
            { state = RegularGame
            , seed = newSeed
            , numMines = numMines
            , grid = grid
            , sizer = Idle
            , pointerPosition = Nothing
            }
    in
        ( initialModel, Cmd.none )


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        CellClick columnNum rowNum ->
            case Helpers.gridState model.grid of
                NewGrid ->
                    let
                        newGrid =
                            Matrix.update columnNum rowNum Helpers.markRevealed model.grid

                        ( seed, gridWithMines ) =
                            Helpers.addRandomMinesAndUpdateNumbers
                                model.numMines
                                model.seed
                                newGrid

                        finalGrid =
                            Helpers.reveal columnNum rowNum gridWithMines
                    in
                        ( { model | seed = seed, grid = finalGrid }, Cmd.none )

                OngoingGrid ->
                    let
                        newGrid =
                            Helpers.reveal columnNum rowNum model.grid
                    in
                        ( { model | grid = newGrid }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        NumMinesChange string ->
            let
                width =
                    Matrix.width model.grid

                height =
                    Matrix.height model.grid

                numMines =
                    Result.withDefault 0 (String.toInt string)
                        |> Helpers.clampNumMines width height
            in
                ( { model | numMines = numMines }, Cmd.none )

        MouseDown pointerPosition ->
            ( { model
                | sizer =
                    Dragging
                        { pointerPosition = pointerPosition
                        , width = Matrix.width model.grid
                        , height = Matrix.height model.grid
                        }
                , pointerPosition = Just pointerPosition
              }
            , Cmd.none
            )

        MouseUp ->
            ( { model | sizer = Idle, pointerPosition = Nothing }, Cmd.none )

        MouseMove pointerPosition ->
            let
                { width, height } =
                    case model.sizer of
                        Dragging { width, height } ->
                            { width = width, height = height }

                        _ ->
                            { width = Matrix.width model.grid
                            , height = Matrix.height model.grid
                            }

                pointerMovement =
                    Helpers.calculatePointerMovement
                        model.sizer
                        (Just pointerPosition)

                newWidth =
                    Helpers.calculateSize width pointerMovement.dx
                        |> Helpers.clampWidth

                newHeight =
                    Helpers.calculateSize height pointerMovement.dy
                        |> Helpers.clampHeight

                grid =
                    Helpers.createEmptyGrid newWidth newHeight

                numMines =
                    Helpers.clampNumMines newWidth newHeight model.numMines
            in
                ( { model
                    | grid = grid
                    , numMines = numMines
                    , pointerPosition = Just pointerPosition
                  }
                , Cmd.none
                )
