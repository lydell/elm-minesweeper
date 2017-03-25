module Html.Events.Custom exposing (onChange, onRightClick)

{-|
Custom HTML events.

# Mouse Helpers
@docs onRightClick

# Form Helpers
@docs onChange
-}

import Html exposing (Attribute)
import Html.Events
import Json.Decode exposing (Decoder)


{-| -}
onRightClick : msg -> Attribute msg
onRightClick tagger =
    Html.Events.onWithOptions "contextmenu"
        { stopPropagation = True, preventDefault = True }
        (Json.Decode.succeed tagger)


{-| Like `onInput`, but only afte the input has been blurred.
-}
onChange : (String -> msg) -> Attribute msg
onChange tagger =
    Html.Events.on "change"
        (Json.Decode.map tagger Html.Events.targetValue)
