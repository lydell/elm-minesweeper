port module Main exposing (..)

import Decoders
import Encoders
import Grid
import Html
import Html.Events.Custom exposing (KeyDetails)
import Json.Decode
import Json.Encode
import Random.Pcg as Random
import Regex exposing (Regex, HowMany(All))
import Set
import Task
import Types exposing (..)
import View
import View.Cell as Cell
import Window


type alias Flags =
    { debug : Bool
    , randomSeed : Int
    , localStorageModelString : Maybe String
    }


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = updateWithLocalStorage
        , view = View.view
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        seed =
            Random.initialSeed flags.randomSeed

        localStorageModelResult =
            case flags.localStorageModelString of
                Just localStorageModelString ->
                    Json.Decode.decodeString
                        Decoders.localStorageModelDecoder
                        localStorageModelString
                        |> Result.mapError
                            (Debug.log "Failed to decode localStorageModel")

                Nothing ->
                    Err "No localStorageModel provided. Using defaults."

        stored accessor default =
            case localStorageModelResult of
                Ok localStorageModel ->
                    accessor localStorageModel

                Err _ ->
                    default

        ( newSeed, grid ) =
            Grid.initialGrid seed

        initialModel =
            { debug = flags.debug
            , seed = newSeed
            , givenUp = stored .givenUp False
            , grid = stored .grid grid
            , selectedCell = stored .selectedCell Nothing
            , focus = NoFocus
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


updateWithLocalStorage : Msg -> Model -> ( Model, Cmd Msg )
updateWithLocalStorage msg model =
    let
        ( newModel, cmd ) =
            update msg model

        localStorageCmd =
            Json.Encode.encode 0 (Encoders.modelEncoder model)
                |> setLocalStorageModel
    in
        ( newModel, Cmd.batch [ cmd, localStorageCmd ] )


port setLocalStorageModel : String -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Change_WidthSelect string ->
            ( updateGridSize
                (parseWidth model string)
                (Grid.height model.grid)
                model
            , Cmd.none
            )

        Change_HeightSelect string ->
            ( updateGridSize
                (Grid.width model.grid)
                (parseHeight model string)
                model
            , Cmd.none
            )

        Change_NumMinesInput string ->
            ( updateNumMines (parseNumMines model string) model
            , Cmd.none
            )

        Click_Cell x y ->
            reveal x y model

        RightClick_Cell x y ->
            flag x y model

        MouseEnter_Cell x y ->
            let
                cmd =
                    if model.focus == ControlsFocus then
                        Cmd.none
                    else
                        Cell.focus x y
            in
                ( { model | selectedCell = Just ( x, y ) }, cmd )

        MouseLeave_Cell x y ->
            ( { model | selectedCell = Nothing }, Cmd.none )

        Focus_Cell x y ->
            ( { model
                | selectedCell = Just ( x, y )
                , focus = CellFocus
              }
            , Cmd.none
            )

        Blur_Cell _ _ ->
            ( { model | selectedCell = Nothing, focus = NoFocus }, Cmd.none )

        Keydown_Cell x y keyDetails ->
            keydown x y keyDetails model

        Keydown_Grid keyDetails ->
            keydown -1 -1 keyDetails model

        Click_GiveUpButton ->
            ( { model | givenUp = True }, View.focusPlayAgainButton )

        Click_PlayAgainButton ->
            playAgain model

        FocusIn_Controls ->
            ( { model | focus = ControlsFocus }, Cmd.none )

        FocusOut_Controls ->
            ( { model | focus = NoFocus }, Cmd.none )

        FocusResult _ ->
            ( model, Cmd.none )

        WindowSize size ->
            ( { model | windowSize = size }, Cmd.none )


parseWidth : Model -> String -> Int
parseWidth model string =
    removeNonDigits string
        |> String.toInt
        |> Result.withDefault (Grid.width model.grid)
        |> Grid.clampWidth


parseHeight : Model -> String -> Int
parseHeight model string =
    removeNonDigits string
        |> String.toInt
        |> Result.withDefault (Grid.height model.grid)
        |> Grid.clampHeight


parseNumMines : Model -> String -> Int
parseNumMines model string =
    removeNonDigits string
        |> String.toInt
        |> Result.withDefault (Grid.numMines model.grid)
        |> Grid.clampNumMines
            (Grid.width model.grid)
            (Grid.height model.grid)


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
                (Grid.width model.grid)
                (Grid.height model.grid)
                numMines
                Set.empty
                model.seed
    in
        { model | seed = seed, grid = grid }


reveal : Int -> Int -> Model -> ( Model, Cmd Msg )
reveal x y model =
    case Grid.gameState model.givenUp model.grid of
        NewGame ->
            let
                neighbourCoords =
                    Grid.indexedNeighbours x y model.grid
                        |> List.map Tuple.first

                excludedCoords =
                    Set.fromList (( x, y ) :: neighbourCoords)

                ( seed, grid ) =
                    Grid.createGrid
                        (Grid.width model.grid)
                        (Grid.height model.grid)
                        (Grid.numMines model.grid)
                        excludedCoords
                        model.seed

                finalGrid =
                    Grid.reveal x y grid
            in
                ( { model | seed = seed, grid = finalGrid }
                , View.focusPlayAgainButton
                )

        OngoingGame ->
            case Grid.get x y model.grid of
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
        gameState =
            Grid.gameState model.givenUp model.grid
    in
        if gameState == NewGame || gameState == OngoingGame then
            let
                newGrid =
                    Grid.flag x y model.grid
            in
                focusAfterCellChange x y { model | grid = newGrid }
        else
            ( model, Cmd.none )


focusAfterCellChange : Int -> Int -> Model -> ( Model, Cmd Msg )
focusAfterCellChange x y model =
    if Grid.isGameEnd (Grid.gameState model.givenUp model.grid) then
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
                    ( x + (Grid.width grid) * factorX
                    , y + (Grid.height grid) * factorY
                    )

                SkipBlanksMovement ->
                    Grid.closestUnrevealedCell factorX factorY grid ( x, y )

        clampedX =
            clamp 0 (Grid.width grid - 1) newX

        clampedY =
            clamp 0 (Grid.height grid - 1) newY
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
                (Grid.width model.grid)
                (Grid.height model.grid)
                (Grid.numMines model.grid)
                Set.empty
                model.seed
    in
        ( { model | seed = seed, givenUp = False, grid = grid }
        , View.focusGrid
        )
