module Key exposing (Key, decoder, empty, encode)

import Iso8601
import Json.Decode as D
import Json.Decode.Extra as D
import Json.Encode as E
import Json.Encode.Extra as E
import Time


type alias Key =
    { companyName : String
    , taxId : String
    , email : String
    , password : String
    , creationDate : Maybe Time.Posix
    , expirationDate : Maybe Time.Posix
    }


empty : Key
empty =
    { companyName = ""
    , taxId = ""
    , email = ""
    , password = ""
    , creationDate = Nothing
    , expirationDate = Nothing
    }


encode : Key -> E.Value
encode k =
    E.object
        [ ( "companyName", E.string k.companyName )
        , ( "npwp", E.string k.taxId )
        , ( "email", E.string k.email )
        , ( "password", E.string k.password )
        , ( "creationDate", E.maybe Iso8601.encode k.creationDate )
        , ( "expirationDate", E.maybe Iso8601.encode k.creationDate )
        ]


decoder : D.Decoder Key
decoder =
    D.succeed Key
        |> D.andMap (D.field "companyName" D.string)
        |> D.andMap (D.field "npwp" D.string)
        |> D.andMap (D.field "email" D.string)
        |> D.andMap (D.field "password" D.string)
        |> D.andMap (D.optionalField "creationDate" D.datetime)
        |> D.andMap (D.optionalField "expirationDate" D.datetime)
