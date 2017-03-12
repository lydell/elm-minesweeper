module Main exposing (..)

import Html exposing (Html, button, div, text)


main : Program Never () msg
main =
    Html.beginnerProgram
        { model = initialModel
        , update = update
        , view = view
        }


initialModel : ()
initialModel =
    ()


update : a -> b -> b
update msg model =
    model


view : a -> Html msg
view model =
    Html.text "Hello, world!"
