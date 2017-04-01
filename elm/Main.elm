module Main exposing (..)

import Cell
import Grid
import Html
import Html.Events.Custom exposing (KeyDetails)
import Matrix
import Matrix.Extra
import Random.Pcg as Random
import Regex exposing (Regex, HowMany(All))
import Set
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

        ( newSeed, grid ) =
            Grid.createGrid width height numMines Set.empty seed

        initialModel =
            { debug = flags.debug
            , seed = newSeed
            , grid = grid
            , givenUp = False
            , selectedCell = Nothing
            , focus = FocusNone
            , windowSize = { width = 0, height = 0 }
            }

        initialCmd =
            Cmd.batch
                [ Task.perform WindowSize Window.size
                , View.focusGrid
                ]
    in
        ( initialModel, initialCmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    Window.resizes WindowSize


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CellClick x y ->
            reveal x y model

        CellRightClick x y ->
            flag x y model

        CellBlur _ _ ->
            ( { model | selectedCell = Nothing, focus = FocusNone }, Cmd.none )

        CellFocus x y ->
            ( { model | selectedCell = Just ( x, y ), focus = FocusCell }, Cmd.none )

        CellMouseEnter x y ->
            let
                cmd =
                    if model.focus == FocusControls then
                        Cmd.none
                    else
                        Cell.focus x y
            in
                ( { model | selectedCell = Just ( x, y ) }, cmd )

        CellMouseLeave x y ->
            ( { model | selectedCell = Nothing }, Cmd.none )

        CellKeydown x y keyDetails ->
            keydown x y keyDetails model

        GridKeydown keyDetails ->
            keydown -1 -1 keyDetails model

        GiveUpButtonClick ->
            ( { model | givenUp = True }, View.focusPlayAgainButton )

        PlayAgainButtonClick ->
            playAgain model

        FocusResult e ->
            ( model, Cmd.none )

        WidthChange string ->
            ( updateGridSize
                (parseWidth model string)
                (Matrix.height model.grid)
                model
            , Cmd.none
            )

        HeightChange string ->
            ( updateGridSize
                (Matrix.width model.grid)
                (parseHeight model string)
                model
            , Cmd.none
            )

        NumMinesChange string ->
            ( updateNumMines (parseNumMines model string) model
            , Cmd.none
            )

        ControlsBlur ->
            ( { model | focus = FocusNone }, Cmd.none )

        ControlsFocus ->
            ( { model | focus = FocusControls }, Cmd.none )

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


parseNumMines : Model -> String -> Int
parseNumMines model string =
    let
        width =
            Matrix.width model.grid

        height =
            Matrix.height model.grid
    in
        removeNonDigits string
            |> String.toInt
            |> Result.withDefault (Grid.numMines model.grid)
            |> Grid.clampNumMines width height


nonDigitRegex : Regex
nonDigitRegex =
    Regex.regex "\\D"


removeNonDigits : String -> String
removeNonDigits =
    Regex.replace All nonDigitRegex (always "")


updateGridSize : Int -> Int -> Model -> Model
updateGridSize width height model =
    let
        clampedWidth =
            Grid.clampWidth width

        clampedHeight =
            Grid.clampHeight height

        numMines =
            Grid.suggestNumMines clampedWidth clampedHeight

        ( seed, grid ) =
            Grid.createGrid
                clampedWidth
                clampedHeight
                numMines
                Set.empty
                model.seed
    in
        { model | seed = seed, grid = grid }


updateNumMines : Int -> Model -> Model
updateNumMines numMines model =
    let
        ( seed, grid ) =
            Grid.createGrid
                (Matrix.width model.grid)
                (Matrix.height model.grid)
                numMines
                Set.empty
                model.seed
    in
        { model | seed = seed, grid = grid }


reveal : Int -> Int -> Model -> ( Model, Cmd Msg )
reveal x y model =
    case Grid.gridState model.givenUp model.grid of
        NewGrid ->
            let
                neighbourCoords =
                    Matrix.Extra.indexedNeighbours x y model.grid
                        |> List.map Tuple.first

                excludedCoords =
                    Set.fromList (( x, y ) :: neighbourCoords)

                ( seed, grid ) =
                    Grid.createGrid
                        (Matrix.width model.grid)
                        (Matrix.height model.grid)
                        (Grid.numMines model.grid)
                        excludedCoords
                        model.seed

                finalGrid =
                    Grid.reveal x y grid
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
                        focusAfterCellChange x y { model | grid = newGrid }

                Just (Cell Revealed Hint) ->
                    if Grid.cellNumber x y model.grid == 0 then
                        ( model, Cmd.none )
                    else
                        let
                            newGrid =
                                Grid.revealNeighbours x y model.grid
                        in
                            focusAfterCellChange x y { model | grid = newGrid }

                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


flag : Int -> Int -> Model -> ( Model, Cmd Msg )
flag x y model =
    let
        gridState =
            Grid.gridState model.givenUp model.grid
    in
        if gridState == NewGrid || gridState == OngoingGrid then
            let
                newGrid =
                    Grid.flag x y model.grid
            in
                focusAfterCellChange x y { model | grid = newGrid }
        else
            ( model, Cmd.none )


focusAfterCellChange : Int -> Int -> Model -> ( Model, Cmd Msg )
focusAfterCellChange x y model =
    if Grid.isGameEnd (Grid.gridState model.givenUp model.grid) then
        ( model, View.focusPlayAgainButton )
    else
        ( model, Cell.focus x y )


keydown : Int -> Int -> KeyDetails -> Model -> ( Model, Cmd Msg )
keydown x y { key, altKey, ctrlKey, metaKey, shiftKey } model =
    let
        jumpHack =
            if x == -1 && y == -1 then
                -- When the grid is focused but there's no selected cell.
                1
            else
                0

        modifiers =
            [ altKey, ctrlKey, metaKey, shiftKey ]

        onlyOneModifier =
            List.foldl xor False modifiers

        movement =
            if onlyOneModifier then
                if ctrlKey then
                    EdgeMovement
                else if shiftKey then
                    SkipBlanksMovement
                else
                    FixedMovement (4 + jumpHack)
            else
                FixedMovement 1

        moveFocusHelper direction =
            ( model, moveFocus x y model.grid movement direction )
    in
        case key of
            "ArrowLeft" ->
                moveFocusHelper Left

            "ArrowRight" ->
                moveFocusHelper Right

            "ArrowUp" ->
                moveFocusHelper Up

            "ArrowDown" ->
                moveFocusHelper Down

            "Tab" ->
                if List.all not modifiers then
                    ( model, View.focusControls Forward )
                else if onlyOneModifier && shiftKey then
                    ( model, View.focusControls Backward )
                else
                    ( model, Cmd.none )

            "Enter" ->
                reveal x y model

            " " ->
                reveal x y model

            "Backspace" ->
                flag x y model

            "Delete" ->
                flag x y model

            _ ->
                if String.length key == 1 then
                    flag x y model
                else
                    ( model, Cmd.none )


moveFocus : Int -> Int -> Grid -> Movement -> Direction -> Cmd Msg
moveFocus x y grid movement direction =
    let
        ( factorX, factorY ) =
            case direction of
                Left ->
                    ( -1, 0 )

                Right ->
                    ( 1, 0 )

                Up ->
                    ( 0, -1 )

                Down ->
                    ( 0, 1 )

        ( newX, newY ) =
            case movement of
                FixedMovement num ->
                    ( x + num * factorX, y + num * factorY )

                EdgeMovement ->
                    ( x + (Matrix.width grid) * factorX
                    , y + (Matrix.height grid) * factorY
                    )

                SkipBlanksMovement ->
                    Grid.closestUnrevealedCell factorX factorY grid ( x, y )

        clampedX =
            clamp 0 (Matrix.width grid - 1) newX

        clampedY =
            clamp 0 (Matrix.height grid - 1) newY
    in
        if clampedX == x && clampedY == y then
            Cmd.none
        else
            Cell.focus clampedX clampedY


playAgain : Model -> ( Model, Cmd Msg )
playAgain model =
    let
        ( seed, grid ) =
            Grid.createGrid
                (Matrix.width model.grid)
                (Matrix.height model.grid)
                (Grid.numMines model.grid)
                Set.empty
                model.seed
    in
        ( { model | seed = seed, grid = grid, givenUp = False }
        , View.focusGrid
        )
