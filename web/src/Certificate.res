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

open RescriptStruct

let struct = S.object(o => {
  companyName: o->S.field("companyName", S.string()),
  taxId: o->S.field("npwp", S.string()),
  email: o->S.field("email", S.string()),
  password: o->S.field("password", S.string()),
  creationDate: o->S.field("creationDate", S.option(S.float())),
  expirationDate: o->S.field("expirationDate", S.option(S.float())),
})

let encode = (data): JSON.t => {
  data->S.serializeOrRaiseWith(struct)
}

let decode = data => {
  data->S.parseOrRaiseWith(struct)
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
