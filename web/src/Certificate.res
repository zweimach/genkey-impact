type t = {
  companyName: string,
  taxId: string,
  email: string,
  password: string,
  creationDate: option<float>,
  expirationDate: option<float>,
}

let make = (~companyName, ~taxId, ~email, ~password, ~creationDate, ~expirationDate) => {
  {
    companyName,
    taxId,
    email,
    password,
    creationDate,
    expirationDate,
  }
}

let empty = make(
  ~companyName="",
  ~taxId="",
  ~email="",
  ~password="",
  ~creationDate=None,
  ~expirationDate=None,
)

let encode = (data): JSON.t => {
  open! Json.Encode
  let fields = [
    ("companyName", string(data.companyName)),
    ("npwp", string(data.taxId)),
    ("email", string(data.email)),
    ("password", string(data.password)),
  ]
  data.creationDate->Option.forEach(v => Array.push(fields, ("creationDate", float(v))))
  data.expirationDate->Option.forEach(v => Array.push(fields, ("expirationDate", float(v))))
  object(fields)
}

let decoder: Json.Decode.t<t> = {
  open! Json.Decode
  succeed((companyName, taxId, email, password, creationDate, expirationDate) => {
    companyName,
    taxId,
    email,
    password,
    creationDate,
    expirationDate,
  })
  ->andMap(field("companyName", string))
  ->andMap(field("npwp", string))
  ->andMap(field("email", string))
  ->andMap(field("password", string))
  ->andMap(field("creationDate", nullable(float)))
  ->andMap(field("expirationDate", nullable(float)))
}

let submit = async (apiUrl: string, data: t): result<unit, string> => {
  open Webapi
  open Fetch
  let requestInit = RequestInit.make(
    ~method_=Post,
    ~mode=CORS,
    ~credentials=Include,
    ~body=data->encode->JSON.stringify->BodyInit.make,
    ~headers=HeadersInit.makeWithArray([("content-type", "application/json")]),
    (),
  )
  try {
    let response = await fetchWithInit(apiUrl ++ "/pkcs12", requestInit)
    if !(response->Response.ok) {
      let error = await response->Response.text
      Error(error)
    } else {
      let result = await response->Response.blob
      Utils.downloadBlob(result, data.taxId ++ ".p12")
      Ok()
    }
  } catch {
  | Exn.Error(exn) => exn->Exn.message->Option.getWithDefault("Failed to make request.")->Error
  }
}
