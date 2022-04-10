module Key exposing (Key, decoder, empty, encode)

import Json.Decode as D
import Json.Encode as E


type alias Key =
    { companyName : String
    , taxId : String
    , email : String
    , password : String
    }


empty : Key
empty =
    { companyName = ""
    , taxId = ""
    , email = ""
    , password = ""
    }


encode : Key -> E.Value
encode k =
    E.object
        [ ( "companyName", E.string k.companyName )
        , ( "npwp", E.string k.taxId )
        , ( "email", E.string k.email )
        , ( "password", E.string k.password )
        ]


decoder : D.Decoder Key
decoder =
    D.map4 Key
        (D.field "companyName" D.string)
        (D.field "npwp" D.string)
        (D.field "email" D.string)
        (D.field "password" D.string)
