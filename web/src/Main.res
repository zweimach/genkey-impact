%%raw(`import "./style.css"`)

let _ = switch ReactDOM.querySelector("#root") {
| None => Exn.raiseError("#root element not found")
| Some(element) =>
  ReactDOM.Client.createRoot(element)->ReactDOM.Client.Root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  )
}
