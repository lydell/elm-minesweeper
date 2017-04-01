module Html.Events.Custom exposing (KeyDetails, onChange, onFocusIn, onFocusOut, onKeydown, onRightClick)

{-|
Custom HTML events.

# Mouse Helpers
@docs onRightClick

# Form Helpers
@docs onChange

# Focus Helpers
@docs onFocusIn, onFocusOut

# Keyboard Helpers
@docs onKeydown
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


{-| -}
onFocusIn : msg -> Attribute msg
onFocusIn tagger =
    Html.Events.on "focusin" (Json.Decode.succeed tagger)


{-| -}
onFocusOut : msg -> Attribute msg
onFocusOut tagger =
    Html.Events.on "focusout" (Json.Decode.succeed tagger)


{-| -}
type alias KeyDetails =
    { key : String
    , altKey : Bool
    , ctrlKey : Bool
    , metaKey : Bool
    , shiftKey : Bool
    }


{-| -}
onKeydown : (KeyDetails -> msg) -> Attribute msg
onKeydown tagger =
    Html.Events.onWithOptions "keydown"
        { stopPropagation = True, preventDefault = True }
        (Json.Decode.map tagger keyDecoder)


keyDecoder : Decoder KeyDetails
keyDecoder =
    Json.Decode.map5 KeyDetails
        (Json.Decode.field "key" Json.Decode.string)
        (Json.Decode.field "altKey" Json.Decode.bool)
        (Json.Decode.field "ctrlKey" Json.Decode.bool)
        (Json.Decode.field "metaKey" Json.Decode.bool)
        (Json.Decode.field "shiftKey" Json.Decode.bool)
