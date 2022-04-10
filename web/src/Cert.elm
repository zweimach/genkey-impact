module Cert exposing (..)

import Bytes exposing (Bytes)
import File exposing (File)
import File.Download as DL


type alias Cert =
    File


download : String -> Bytes -> Cmd msg
download name bytes =
    DL.bytes (name ++ ".p12") "application/x-pkcs12" bytes
