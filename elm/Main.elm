module Main exposing (..)

import Grid
import Html
import Matrix
import Random.Pcg as Random
import Regex exposing (Regex, HowMany(All))
import Set
import Task
import Types exposing (..)
import View exposing (view)
import Window


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
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        seed =
            Random.initialSeed flags.randomSeed

        width =
            Grid.minWidth

        height =
            Grid.minHeight

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
            , windowSize = { width = 0, height = 0 }
            }

        initialCmd =
            Task.perform WindowSize Window.size
    in
        ( initialModel, initialCmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    Window.resizes WindowSize


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
                                ( model.seed, Grid.reset model.grid )

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
                        newGrid =
                            Grid.flag x y (Grid.reset model.grid)

                        ( seed, gridWithMines ) =
                            Grid.addRandomMinesAndUpdateNumbers
                                model.numMines
                                (Set.singleton ( x, y ))
                                ( model.seed, newGrid )
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

        WidthChange string ->
            let
                width =
                    parseWidth model string

                height =
                    Matrix.height model.grid
            in
                ( updateGridSize width height model, Cmd.none )

        HeightChange string ->
            let
                width =
                    Matrix.width model.grid

                height =
                    parseHeight model string
            in
                ( updateGridSize width height model, Cmd.none )

        NumMinesChange string ->
            let
                numMines =
                    parseNumDigits model string
            in
                ( { model | numMines = numMines }, Cmd.none )

        WindowSize size ->
            ( { model | windowSize = size }, Cmd.none )


parseWidth : Model -> String -> Int
parseWidth model string =
    removeNonDigits string
        |> String.toInt
        |> Result.withDefault (Matrix.width model.grid)
        |> Grid.clampWidth


parseHeight : Model -> String -> Int
parseHeight model string =
    removeNonDigits string
        |> String.toInt
        |> Result.withDefault (Matrix.height model.grid)
        |> Grid.clampHeight


parseNumDigits : Model -> String -> Int
parseNumDigits model string =
    let
        width =
            Matrix.width model.grid

        height =
            Matrix.height model.grid
    in
        removeNonDigits string
            |> String.toInt
            |> Result.withDefault model.numMines
            |> Grid.clampNumMines width height


updateGridSize : Int -> Int -> Model -> Model
updateGridSize width height model =
    let
        clampedWidth =
            Grid.clampWidth width

        clampedHeight =
            Grid.clampHeight height

        grid =
            Grid.defaultGrid clampedWidth clampedHeight

        numMines =
            Grid.suggestNumMines clampedWidth clampedHeight
    in
        { model | grid = grid, numMines = numMines }


nonDigitRegex : Regex
nonDigitRegex =
    Regex.regex "\\D"


removeNonDigits : String -> String
removeNonDigits =
    Regex.replace All nonDigitRegex (always "")
