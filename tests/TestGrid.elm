module TestGrid exposing (..)

import Expect
import Fuzz exposing (int)
import Grid
import Test exposing (..)


suite : Test
suite =
    describe "The Grid Module"
        [ describe "suggestNumMines"
            [ test "9x9 -> 10" <|
                \_ ->
                    Grid.suggestNumMines 9 9
                        |> Expect.equal 10
            , test "16x16 -> 40" <|
                \_ ->
                    Grid.suggestNumMines 16 16
                        |> Expect.equal 40
            , test "30x16 -> 99" <|
                \_ ->
                    Grid.suggestNumMines 30 16
                        |> Expect.equal 99
            , fuzz2 int int "always suggests a valid number of mines" <|
                \width height ->
                    Grid.suggestNumMines width height
                        |> Expect.all
                            [ Expect.atLeast Grid.minNumMines
                            , Expect.atMost (Grid.maxNumMines width height)
                            ]
            ]
        ]
