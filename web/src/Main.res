%%raw(`import "./style.css"`)

let _ = switch ReactDOM.querySelector("#root") {
| None => JsError.throwWithMessage("#root element not found")
| Some(element) =>
  ReactDOM.Client.createRoot(element)->ReactDOM.Client.Root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  )
}
