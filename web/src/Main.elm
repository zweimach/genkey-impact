module Main exposing (main)

import Browser exposing (Document)
import Bytes exposing (Bytes)
import Cert exposing (Cert)
import File.Download as DL
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Key exposing (Key)
import VitePluginHelper as V


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Flags =
    { apiUrl : Maybe String
    }


type alias Model =
    { form : Key
    , file : Maybe Cert
    , status : Status
    , apiUrl : String
    }


type Status
    = Ready
    | Failure Error
    | Loading
    | Success


type Error
    = ServerError String
    | EnvError


type Msg
    = InputCompanyName String
    | InputTaxId String
    | InputEmail String
    | InputPassword String
    | SubmitForm
    | ClearForm
    | GotBytes Bytes
    | ChangeStatus Status


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( apiUrl, status ) =
            case flags.apiUrl of
                Nothing ->
                    ( "", Failure EnvError )

                Just "" ->
                    ( "", Failure EnvError )

                Just s ->
                    ( s, Ready )
    in
    ( { form = Key.empty
      , file = Nothing
      , status = status
      , apiUrl = apiUrl
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputCompanyName companyName ->
            updateForm (\form -> { form | companyName = companyName }) model

        InputTaxId taxId ->
            updateForm (\form -> { form | taxId = taxId |> String.replace "." "" |> String.replace "-" "" }) model

        InputEmail email ->
            updateForm (\form -> { form | email = email }) model

        InputPassword password ->
            updateForm (\form -> { form | password = password }) model

        SubmitForm ->
            submitForm model

        ClearForm ->
            clearForm model

        GotBytes bytes ->
            downloadFile bytes model

        ChangeStatus status ->
            ( changeStatus status model, Cmd.none )


changeStatus : Status -> Model -> Model
changeStatus status model =
    { model | status = status }


downloadFile : Bytes -> Model -> ( Model, Cmd msg )
downloadFile bytes model =
    ( changeStatus Success model, DL.bytes (model.form.taxId ++ ".p12") "application/x-pkcs12" bytes )


updateForm : (Key -> Key) -> Model -> ( Model, Cmd msg )
updateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )


submitForm : Model -> ( Model, Cmd Msg )
submitForm model =
    let
        toMsg result =
            case result of
                Ok b ->
                    GotBytes b

                Err e ->
                    ChangeStatus <| Failure e

        toResult response =
            case response of
                Http.BadUrl_ s ->
                    Err (ServerError <| "You did not provide a valid URL: (" ++ s ++ ").")

                Http.Timeout_ ->
                    Err (ServerError "It took too long to get a response.")

                Http.NetworkError_ ->
                    Err (ServerError "Cannot reach the server.")

                Http.BadStatus_ data _ ->
                    Err (ServerError <| "Error " ++ String.fromInt data.statusCode ++ ": " ++ data.statusText ++ ".")

                Http.GoodStatus_ _ body ->
                    Ok body
    in
    ( changeStatus Loading model
    , Http.riskyRequest
        { method = "POST"
        , headers = []
        , url = model.apiUrl ++ "/pkcs12"
        , body = Http.jsonBody <| Key.encode model.form
        , expect = Http.expectBytesResponse toMsg toResult
        , timeout = Just 30000
        , tracker = Nothing
        }
    )


clearForm : Model -> ( Model, Cmd msg )
clearForm model =
    ( { model | form = Key.empty }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Document Msg
view model =
    Document "Genkey Impact"
        [ div [ class "h-full flex flex-col justify-start items-center p-4 text-lg" ]
            [ h1 [ class "my-4 font-serif text-3xl font-bold text-sky-700" ] [ text "Genkey Impact" ]
            , Html.form [ novalidate True, onSubmit SubmitForm, class "w-full sm:max-w-screen-sm flex flex-col justify-start items-stretch gap-4 p-2 md:p-8" ]
                [ viewInput "text" "Company Name" model.form.companyName InputCompanyName
                , viewInput "text" "NPWP" model.form.taxId InputTaxId
                , viewInput "email" "Email" model.form.email InputEmail
                , viewInput "password" "Password" model.form.password InputPassword
                , button
                    [ type_ "submit"
                    , class "px-4 py-2 rounded border-2 border-sky-400 bg-sky-300 focus:outline-none hover:bg-sky-500 active:border-indigo-600 focus:bg-sky-500 font-semibold text-blue-800 disabled:bg-gray-300 disabled:border-gray-300 disabled:text-gray-700"
                    , disabled (model.status == Loading || model.status == Failure EnvError)
                    ]
                    [ text "Submit" ]
                , button
                    [ type_ "button"
                    , onClick ClearForm
                    , class "px-4 py-2 rounded border-2 border-sky-400 bg-sky-100 focus:outline-none hover:bg-sky-200 active:border-indigo-600 focus:bg-sky-200 font-semibold text-blue-800"
                    , disabled (model.status == Loading)
                    ]
                    [ text "Clear" ]
                ]
            , viewMessage model.status
            ]
        ]


viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
    input
        [ class "px-4 py-2 rounded bg-white border-2 border-sky-400 hover:border-indigo-500 focus:outline-none focus:border-blue-500 placeholder:text-sky-300"
        , type_ t
        , placeholder p
        , value v
        , onInput toMsg
        ]
        []


viewMessage : Status -> Html msg
viewMessage status =
    let
        ( icon, primary, secondary ) =
            case status of
                Failure _ ->
                    ( V.asset "/assets/error.svg", "border-red-500 bg-rose-50", "text-red-800" )

                Success ->
                    ( V.asset "/assets/success.svg", "border-emerald-600 bg-emerald-50", "text-green-800" )

                Ready ->
                    ( V.asset "/assets/info.svg", "border-blue-400 bg-sky-50", "text-blue-800" )

                Loading ->
                    ( V.asset "/assets/loading.svg", "border-cyan-300 bg-cyan-50", "text-cyan-700" )

        message =
            case status of
                Ready ->
                    "Please input your digital certificate information."

                Loading ->
                    "Loading ..."

                Failure e ->
                    case e of
                        EnvError ->
                            "The API URL is empty. You can't send information to the server."

                        ServerError s ->
                            s

                Success ->
                    "Your digital certificate has been created. Please check your downloads."
    in
    div [ class primary, class "max-w-xl flex justify-center items-center gap-4 p-4 rounded-lg border-4" ]
        [ img [ src icon, width 48, height 48 ] []
        , p [ class secondary, class "text-ellipsis overflow-hidden" ] [ text message ]
        ]
