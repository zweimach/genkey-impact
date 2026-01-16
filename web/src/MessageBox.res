open Utils

@react.component
let make = (~status: AppStatus.t) => {
  let (src, primary, secondary) = switch status {
  | Ready => ("/info.svg", "border-blue-400 bg-sky-50", "text-blue-800")
  | Failure(_) => ("/error.svg", "border-red-500 bg-rose-50", "text-red-800")
  | Success => ("/success.svg", "border-emerald-600 bg-emerald-50", "text-green-800")
  | Loading => ("/loading.svg", "border-cyan-300 bg-cyan-50", "text-cyan-700")
  }
  let message = switch status {
  | Ready => "Please input your digital certificate information."
  | Failure(e) =>
    switch e {
    | EnvError => "The API URL is empty. You can't send information to the server."
    | ServerError(s) => s
    }
  | Success => "Your digital certificate has been created. Please check your downloads."
  | Loading => "Loading ..."
  }
  <div
    className={"max-w-xl flex justify-center items-center gap-4 p-4 rounded-lg border-4 " ++
    primary}
  >
    <img src width="48" height="48" alt="status icon" />
    <p className={"text-ellipsis overflow-hidden " ++ secondary}> {message->React.string} </p>
  </div>
}
