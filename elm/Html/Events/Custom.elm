module Html.Events.Custom
    exposing
        ( Button(..)
        , PointerPosition
        , onChange
        , onMouseDown
        , onMouseMove
        , onRightClick
        )

{-|
Custom HTML events.

# Mouse Helpers
@docs Button, PointerPosition, onRightClick, onMouseDown, onMouseMove

# Form Helpers
@docs onChange
-}

import Html exposing (Attribute)
import Html.Events
import Json.Decode exposing (Decoder)


{-| The different types of mouse buttons that may be recognized by browsers.
-}
type Button
    = LeftButton
    | Wheel
    | RightButton
    | BackButton
    | ForwardButton
    | UnknownButton


{-| The position on the screen of a mouse pointer or a finger (in case of touch
screens.)
-}
type alias PointerPosition =
    { screenX : Int
    , screenY : Int
    }


{-| -}
onRightClick : msg -> Attribute msg
onRightClick tagger =
    Html.Events.onWithOptions "contextmenu"
        { stopPropagation = True, preventDefault = True }
        (Json.Decode.succeed tagger)


{-| Like the standard `onMouseDown`, but with the clicked button and the pointer
position passed along.
-}
onMouseDown : (Button -> PointerPosition -> msg) -> Attribute msg
onMouseDown tagger =
    Html.Events.on "mousedown"
        (Json.Decode.map2 tagger buttonDecoder pointerPositionDecoder)


{-| -}
onMouseMove : (PointerPosition -> msg) -> Attribute msg
onMouseMove tagger =
    Html.Events.on "mousemove"
        (Json.Decode.map tagger pointerPositionDecoder)


buttonDecoder : Decoder Button
buttonDecoder =
    Json.Decode.field "button" Json.Decode.int
        |> Json.Decode.map parseButtonNumber


parseButtonNumber : Int -> Button
parseButtonNumber number =
    case number of
        0 ->
            LeftButton

        1 ->
            Wheel

        2 ->
            RightButton

        3 ->
            BackButton

        4 ->
            ForwardButton

        _ ->
            UnknownButton


pointerPositionDecoder : Decoder PointerPosition
pointerPositionDecoder =
    Json.Decode.map2 PointerPosition
        (Json.Decode.field "screenX" Json.Decode.int)
        (Json.Decode.field "screenY" Json.Decode.int)


{-| Like `onInput`, but only afte the input has been blurred.
-}
onChange : (String -> msg) -> Attribute msg
onChange tagger =
    Html.Events.on "change"
        (Json.Decode.map tagger Html.Events.targetValue)
