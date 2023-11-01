module DomainError = {
  type t =
    | ServerError(string)
    | EnvError
}

module AppStatus = {
  type t =
    | Ready
    | Failure(DomainError.t)
    | Loading
    | Success
}

@val external apiUrl: option<string> = "import.meta.env.VITE_API_URL"

open Webapi

@send external click: Dom.Element.t => unit = "click"

let downloadBlob = (blob: Blob.t, filename: string) => {
  let document = Dom.document
  let url = Url.createObjectURLFromBlob(blob)
  let anchor = document->Dom.Document.createElement("a")
  anchor->Dom.Element.setAttribute("href", url)
  anchor->Dom.Element.setAttribute("download", filename)
  switch document->Dom.Document.asHtmlDocument->Option.flatMap(Dom.HtmlDocument.body) {
  | Some(body) => {
      body->Dom.Element.appendChild(~child=anchor)
      anchor->click
      Dom.Element.remove(anchor)
      Url.revokeObjectURL(url)
    }
  | _ => ignore()
  }
}
