module Api exposing (..)

import Http


type alias BaseConfig msg a =
    { a
        | headers : List Http.Header
        , url : String
        , body : Http.Body
        , expect : Http.Expect msg
        , timeout : Maybe Float
        , tracker : Maybe String
        , withCredentials : Bool
    }


type alias RequestConfig msg =
    BaseConfig msg { method : String }


request : RequestConfig msg -> Cmd msg
request config =
    let
        requestFunc =
            if config.withCredentials then
                Http.riskyRequest

            else
                Http.request
    in
    requestFunc
        { method = config.method
        , headers = config.headers
        , url = config.url
        , body = config.body
        , expect = config.expect
        , timeout = config.timeout
        , tracker = config.tracker
        }


type alias ApiConfig msg =
    BaseConfig msg {}


get : ApiConfig msg -> Cmd msg
get config =
    request
        { method = "GET"
        , headers = config.headers
        , url = config.url
        , body = config.body
        , expect = config.expect
        , timeout = config.timeout
        , tracker = config.tracker
        , withCredentials = config.withCredentials
        }


post : ApiConfig msg -> Cmd msg
post config =
    request
        { method = "POST"
        , headers = config.headers
        , url = config.url
        , body = config.body
        , expect = config.expect
        , timeout = config.timeout
        , tracker = config.tracker
        , withCredentials = config.withCredentials
        }
