module Main exposing (..)

import Grid
import Html
import Matrix
import Random.Pcg as Random
import Regex exposing (Regex, HowMany(All))
import Task
import Types exposing (..)
import View
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
        , view = View.view
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
                0
                0
                ( seed, emptyGrid )

        initialModel =
            { debug = flags.debug
            , seed = newSeed
            , numMines = numMines
            , grid = grid
            , givenUp = False
            , windowSize = { width = 0, height = 0 }
            }

        initialCmd =
            Task.perform WindowSize Window.size
    in
        ( initialModel, initialCmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    Window.resizes WindowSize


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CellClick x y ->
            case Grid.gridState model.givenUp model.grid of
                NewGrid ->
                    let
                        ( seed, gridWithMines ) =
                            Grid.addRandomMinesAndUpdateNumbers
                                model.numMines
                                x
                                y
                                ( model.seed, Grid.reset model.grid )

                        finalGrid =
                            Grid.reveal x y gridWithMines
                    in
                        ( { model | seed = seed, grid = finalGrid }
                        , View.focusPlayAgainButton
                        )

                OngoingGrid ->
                    case Matrix.get x y model.grid of
                        Just (Cell Unrevealed _) ->
                            let
                                newGrid =
                                    Grid.reveal x y model.grid
                            in
                                ( { model | grid = newGrid }
                                , View.focusPlayAgainButton
                                )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CellRightClick x y ->
            case Grid.gridState model.givenUp model.grid of
                NewGrid ->
                    let
                        newGrid =
                            Grid.flag x y (Grid.reset model.grid)

                        ( seed, gridWithMines ) =
                            Grid.addRandomMinesAndUpdateNumbers
                                (model.numMines - 1)
                                x
                                y
                                ( model.seed, newGrid )
                    in
                        ( { model | seed = seed, grid = gridWithMines }
                        , View.focusPlayAgainButton
                        )

                OngoingGrid ->
                    let
                        newGrid =
                            Grid.flag x y model.grid
                    in
                        ( { model | grid = newGrid }
                        , View.focusPlayAgainButton
                        )

                _ ->
                    ( model, Cmd.none )

        GiveUpButtonClick ->
            ( { model | givenUp = True }, View.focusPlayAgainButton )

        PlayAgainButtonClick ->
            ( { model
                | grid = Grid.reset model.grid
                , givenUp = False
              }
            , Cmd.none
            )

        PlayAgainButtonFocus _ ->
            -- It doesn't matter if the focus fails. In fact, the button is
            -- attempted to be focused even if it is not present! Perhaps a bit
            -- ugly, but simple.
            ( model, Cmd.none )

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
