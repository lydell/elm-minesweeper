module Main exposing (..)

import Grid
import Html
import Html.Events.Custom exposing (Button(LeftButton))
import Matrix
import Random.Pcg as Random
import Regex exposing (Regex, HowMany(All))
import Set
import Types exposing (..)
import View exposing (view)


type alias Flags =
    { debug : Bool
    , randomSeed : Int
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
            Grid.addRandomMinesAndUpdateNumbers
                numMines
                Set.empty
                ( seed, emptyGrid )

        initialModel =
            { debug = flags.debug
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
                        ( seed, gridWithMines ) =
                            Grid.addRandomMinesAndUpdateNumbers
                                model.numMines
                                (Set.singleton ( x, y ))
                                ( model.seed, model.grid )

                        finalGrid =
                            Grid.reveal x y gridWithMines
                    in
                        ( { model | seed = seed, grid = finalGrid }, Cmd.none )

                OngoingGrid ->
                    case Matrix.get x y model.grid of
                        Just (Cell Unrevealed _) ->
                            ( { model | grid = Grid.reveal x y model.grid }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CellRightClick x y ->
            case Grid.gridState model.grid of
                NewGrid ->
                    let
                        ( seed, gridWithMines ) =
                            Grid.addRandomMinesAndUpdateNumbers
                                model.numMines
                                (Set.singleton ( x, y ))
                                ( model.seed, model.grid )
                    in
                        ( { model | seed = seed, grid = gridWithMines }, Cmd.none )

                OngoingGrid ->
                    ( { model | grid = Grid.flag x y model.grid }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GiveUpButtonClick ->
            ( { model | grid = Grid.detonateAll model.grid }, Cmd.none )

        PlayAgainButtonClick ->
            ( { model | grid = Grid.reset model.grid }, Cmd.none )

        NumMinesChange string ->
            let
                width =
                    Matrix.width model.grid

                height =
                    Matrix.height model.grid

                numMines =
                    removeNonDigits string
                        |> String.toInt
                        |> Result.withDefault model.numMines
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


nonDigitRegex : Regex
nonDigitRegex =
    Regex.regex "\\D"


removeNonDigits : String -> String
removeNonDigits =
    Regex.replace All nonDigitRegex (always "")
