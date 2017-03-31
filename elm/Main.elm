module Main exposing (..)

import Cell
import Grid
import Html
import Html.Events.Custom exposing (KeyDetails)
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
            ( { model
                | grid = Grid.reset model.grid
                , givenUp = False
              }
            , View.focusGrid
            )

        FocusResult e ->
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


reveal : Int -> Int -> Model -> ( Model, Cmd Msg )
reveal x y model =
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
                        focusAfterCellChange x y { model | grid = newGrid }

                Just (Cell Revealed (Hint num)) ->
                    if num == 0 then
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
                focusAfterCellChange x y { model | seed = seed, grid = gridWithMines }

        OngoingGrid ->
            let
                newGrid =
                    Grid.flag x y model.grid
            in
                focusAfterCellChange x y { model | grid = newGrid }

        _ ->
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
                    FixedMovement 4
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
                    closestUnrevealedCell factorX factorY grid ( x, y )

        clampedX =
            clamp 0 (Matrix.width grid - 1) newX

        clampedY =
            clamp 0 (Matrix.height grid - 1) newY
    in
        if clampedX == x && clampedY == y then
            Cmd.none
        else
            Cell.focus clampedX clampedY


closestUnrevealedCell : Int -> Int -> Grid -> ( Int, Int ) -> ( Int, Int )
closestUnrevealedCell dx dy grid ( x, y ) =
    let
        newX =
            x + dx

        newY =
            y + dy
    in
        case Matrix.get newX newY grid of
            Just (Cell Unrevealed _) ->
                ( newX, newY )

            Just _ ->
                closestUnrevealedCell dx dy grid ( newX, newY )

            Nothing ->
                ( x, y )
