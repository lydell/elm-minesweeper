module Main exposing (..)

import Grid
import Html
import Html.Events.Custom exposing (Button(LeftButton))
import Matrix
import Random.Pcg as Random
import Types exposing (..)
import View exposing (view)


type alias Flags =
    { randomSeed : Int
    }


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

        width =
            9

        height =
            9

        numMines =
            Grid.suggestNumMines width height

        emptyGrid =
            Grid.defaultGrid width height

        -- It is not needed to add mines and all at this point, but it makes
        -- debugging easier.
        ( newSeed, grid ) =
            Grid.addRandomMinesAndUpdateNumbers numMines ( seed, emptyGrid )

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
        CellClick x y ->
            case Grid.gridState model.grid of
                NewGrid ->
                    let
                        newGrid =
                            Grid.revealSingle x y (Grid.reset model.grid)

                        ( seed, gridWithMines ) =
                            Grid.addRandomMinesAndUpdateNumbers
                                model.numMines
                                ( model.seed, newGrid )

                        finalGrid =
                            Grid.reveal x y gridWithMines
                    in
                        ( { model | seed = seed, grid = finalGrid }, Cmd.none )

                OngoingGrid ->
                    ( { model | grid = Grid.reveal x y model.grid }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CellRightClick x y ->
            case Grid.gridState model.grid of
                NewGrid ->
                    let
                        newGrid =
                            Grid.flag x y (Grid.reset model.grid)

                        ( seed, gridWithMines ) =
                            Grid.addRandomMinesAndUpdateNumbers
                                model.numMines
                                ( model.seed, newGrid )
                    in
                        ( { model | seed = seed, grid = gridWithMines }, Cmd.none )

                OngoingGrid ->
                    ( { model | grid = Grid.flag x y model.grid }, Cmd.none )

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
                        |> Grid.clampNumMines width height
            in
                ( { model | numMines = numMines }, Cmd.none )

        MouseDown button pointerPosition ->
            case button of
                LeftButton ->
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

                _ ->
                    ( model, Cmd.none )

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
                    Grid.pointerMovement
                        model.sizer
                        (Just pointerPosition)

                newWidth =
                    Grid.gridSize width pointerMovement.dx
                        |> Grid.clampWidth

                newHeight =
                    Grid.gridSize height pointerMovement.dy
                        |> Grid.clampHeight

                grid =
                    Grid.defaultGrid newWidth newHeight

                numMines =
                    Grid.suggestNumMines newWidth newHeight
            in
                ( { model
                    | grid = grid
                    , numMines = numMines
                    , pointerPosition = Just pointerPosition
                  }
                , Cmd.none
                )
