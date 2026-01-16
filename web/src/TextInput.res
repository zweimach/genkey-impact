@react.component
let make = (
  ~onInput: string => unit,
  ~type_="text",
  ~className=?,
  ~defaultValue=?,
  ~placeholder=?,
  ~value=?,
) => {
  <input
    className={String.concatMany(
      "px-4 py-2 rounded-sm bg-white border-2 border-sky-400 hover:border-indigo-500 focus:outline-hidden focus:border-blue-500 placeholder:text-sky-300",
      [" ", className->Option.getOr("")],
    )->String.trim}
    onInput={e => onInput(ReactEvent.Form.target(e)["value"])}
    type_
    ?defaultValue
    ?placeholder
    ?value
  />
}
