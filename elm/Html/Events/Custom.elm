module Html.Events.Custom exposing (KeyDetails, onChange, onFocusIn, onFocusOut, onKeydown, onKeydownWithOptions, onRightClick)

{-| Custom HTML events.


# Mouse Helpers

@docs onRightClick


# Form Helpers

@docs onChange


# Focus Helpers

@docs onFocusIn, onFocusOut


# Keyboard Helpers

@docs onKeydown, onKeydownWithOptions

-}

import Html exposing (Attribute)
import Html.Events exposing (Options)
import Json.Decode as Decode exposing (Decoder)


{-| -}
onRightClick : msg -> Attribute msg
onRightClick tagger =
    Html.Events.onWithOptions "contextmenu"
        { stopPropagation = True, preventDefault = True }
        (Decode.succeed tagger)


{-| Like `onInput`, but only afte the input has been blurred.
-}
onChange : (String -> msg) -> Attribute msg
onChange tagger =
    Html.Events.on "change"
        (Decode.map tagger Html.Events.targetValue)


{-| -}
onFocusIn : msg -> Attribute msg
onFocusIn tagger =
    Html.Events.on "focusin" (Decode.succeed tagger)


{-| -}
onFocusOut : msg -> Attribute msg
onFocusOut tagger =
    Html.Events.on "focusout" (Decode.succeed tagger)


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
onKeydown =
    onKeydownWithOptions { stopPropagation = True, preventDefault = True }


{-| -}
onKeydownWithOptions : Options -> (KeyDetails -> msg) -> Attribute msg
onKeydownWithOptions options tagger =
    Html.Events.onWithOptions "keydown" options (Decode.map tagger keyDecoder)


keyDecoder : Decoder KeyDetails
keyDecoder =
    Decode.map5 KeyDetails
        (Decode.field "key" Decode.string)
        (Decode.field "altKey" Decode.bool)
        (Decode.field "ctrlKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)
        (Decode.field "shiftKey" Decode.bool)
