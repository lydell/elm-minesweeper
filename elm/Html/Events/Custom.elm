module Html.Events.Custom
    exposing
        ( onChange
        , onMouseDown
        , onMouseMove
        , PointerPosition
        )

{-|
Custom HTML events.

# Mouse Helpers
@docs PointerPosition onMouseDown, onMouseMove

# Form Helpers
@docs onChange
-}

import Html exposing (Attribute)
import Html.Events
import Json.Decode exposing (Decoder)


{-| The position on the screen of a mouse pointer or a finger (in case of touch
screens.)
-}
type alias PointerPosition =
    { screenX : Int
    , screenY : Int
    }


{-| Like the standard `onMouseDown`, but with the pointer position passed along.
-}
onMouseDown : (PointerPosition -> msg) -> Attribute msg
onMouseDown tagger =
    Html.Events.on "mousedown"
        (Json.Decode.map tagger pointerPositionDecoder)


{-| -}
onMouseMove : (PointerPosition -> msg) -> Attribute msg
onMouseMove tagger =
    Html.Events.on "mousemove"
        (Json.Decode.map tagger pointerPositionDecoder)


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
