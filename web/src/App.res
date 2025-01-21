open Utils

module Action = {
  type t =
    | InputCompanyName(string)
    | InputTaxId(string)
    | InputEmail(string)
    | InputPassword(string)
    | InputCreationDate(option<float>)
    | InputExpirationDate(option<float>)
    | ClearForm
    | ChangeStatus(AppStatus.t)
    | TogglePassword
    | SetApiUrl(string)
}

module State = {
  type t = {
    form: Certificate.t,
    status: AppStatus.t,
    apiUrl: string,
    showPassword: bool,
  }

  let init = {
    form: Certificate.empty,
    status: Ready,
    apiUrl: "",
    showPassword: false,
  }

  let reducer = (state, action: Action.t) => {
    switch action {
    | InputCompanyName(companyName) => {...state, form: {...state.form, companyName}}
    | InputTaxId(taxId_) => {
        let taxId = taxId_->String.trim->String.replaceRegExp(%re("/[^0-9]/g"), "")
        {...state, form: {...state.form, taxId}}
      }
    | InputEmail(email) => {...state, form: {...state.form, email}}
    | InputPassword(password) => {...state, form: {...state.form, password}}
    | InputCreationDate(date) => {...state, form: {...state.form, creationDate: date}}
    | InputExpirationDate(date) => {...state, form: {...state.form, expirationDate: date}}
    | ClearForm => {...state, form: Certificate.empty}
    | ChangeStatus(status) => {...state, status}
    | TogglePassword => {...state, showPassword: !state.showPassword}
    | SetApiUrl(apiUrl) => {...state, apiUrl}
    }
  }
}

module ThisDate = {
  type t = {
    day: int,
    month: int,
    year: int,
  }

  let empty = (): t => {
    let now = Date.make()
    {
      day: now->Date.getDate,
      month: now->Date.getMonth + 1,
      year: now->Date.getFullYear,
    }
  }

  let toDate = (d: t) => Date.makeWithYMD(~date=d.day, ~month=d.month - 1, ~year=d.year)
}

@react.component
let make = () => {
  let (state, send) = React.useReducer(State.reducer, State.init)
  let (expirationDate, setExpirationDate) = React.useState(() => None)
  let (creationDate, setCreationDate) = React.useState(() => None)

  React.useEffect(() => {
    switch apiUrl {
    | None
    | Some("") =>
      send(ChangeStatus(Failure(EnvError)))
    | Some(v) => send(SetApiUrl(v))
    }
    None
  }, [])

  React.useEffect(() => {
    expirationDate
    ->Option.map(c => c->ThisDate.toDate)
    ->Option.map(c => c->Date.getTime)
    ->InputExpirationDate
    ->send
    None
  }, [expirationDate])

  React.useEffect(() => {
    creationDate
    ->Option.map(c => c->ThisDate.toDate)
    ->Option.map(c => c->Date.getTime)
    ->InputCreationDate
    ->send
    None
  }, [creationDate])

  let submit = React.useCallback(() => {
    send(ChangeStatus(Loading))
    Certificate.submit(state.apiUrl, state.form)
    ->Promise.thenResolve(result => {
      switch result {
      | Ok(_) => send(ChangeStatus(Success))
      | Error(exn) => send(ChangeStatus(Failure(ServerError(exn))))
      }
    })
    ->Promise.done
  }, (state.form, state.apiUrl))

  let reset = React.useCallback(_ => {
    send(ClearForm)
    setExpirationDate(_ => None)
    setCreationDate(_ => None)
  }, [])

  let initExpirationDate = React.useCallback(_ => {
    let now = ThisDate.empty()
    setExpirationDate(_ => Some({...now, year: now.year + 1}))
  }, [])

  let (inputType, inputText, inputClass) = if state.showPassword {
    (
      "text",
      "Hide Password",
      "border-emerald-600 bg-emerald-50 hover:bg-emerald-200 focus:bg-emerald-200 text-green-800",
    )
  } else {
    (
      "password",
      "Show Password",
      "border-red-500 bg-rose-50 hover:bg-rose-200 focus:bg-rose-200 text-red-800",
    )
  }

  let isLoading = state.status == Loading
  let isEnvError = state.status == Failure(EnvError)

  <div className="h-full flex flex-col justify-start items-center gap-4 p-4 text-sm md:text-lg">
    <h1 className="my-4 font-serif text-3xl font-bold text-sky-700">
      {"Genkey Impact"->React.string}
    </h1>
    <form
      className="w-full sm:max-w-screen-sm flex flex-col justify-start items-stretch gap-4 p-2 md:p-8"
      noValidate=true
      onSubmit={e => e->ReactEvent.Form.preventDefault->submit}>
      <TextInput
        placeholder="Company Name"
        defaultValue=state.form.companyName
        onInput={v => send(InputCompanyName(v))}
      />
      <TextInput placeholder="NPWP" value=state.form.taxId onInput={v => send(InputTaxId(v))} />
      <TextInput
        placeholder="Email" defaultValue=state.form.email onInput={v => send(InputEmail(v))}
      />
      <TextInput
        placeholder="Password"
        defaultValue=state.form.password
        onInput={v => send(InputPassword(v))}
        type_=inputType
      />
      <button
        className={"px-4 py-2 rounded border-2 focus:outline-none font-semibold " ++ inputClass}
        type_="button"
        onClick={_ => send(TogglePassword)}>
        {inputText->React.string}
      </button>
      {switch expirationDate {
      | None =>
        <button
          className="px-4 py-2 rounded border-2 border-sky-400 bg-sky-100 focus:outline-none hover:bg-sky-200 active:border-indigo-600 focus:bg-sky-200 font-semibold text-blue-800"
          type_="button"
          onClick={initExpirationDate}>
          {"Add Expiration Date"->React.string}
        </button>
      | Some(date) =>
        <>
          <button
            className="px-4 py-2 rounded border-2 border-sky-400 bg-sky-100 focus:outline-none hover:bg-sky-200 active:border-indigo-600 focus:bg-sky-200 font-semibold text-blue-800"
            type_="button"
            onClick={_ => setExpirationDate(_ => None)}>
            {"Remove Expiration Date"->React.string}
          </button>
          <div className="flex gap-3">
            <TextInput
              className="w-1/3"
              placeholder="Day"
              onInput={v => {
                let day = v->Int.fromString->Option.getOr(date.day)
                setExpirationDate(_ => Some({...date, day}))
              }}
            />
            <TextInput
              className="w-1/3"
              placeholder="Month"
              onInput={v => {
                let month = v->Int.fromString->Option.getOr(date.month)
                setExpirationDate(_ => Some({...date, month}))
              }}
            />
            <TextInput
              className="w-1/3"
              placeholder="Year"
              onInput={v => {
                let year = v->Int.fromString->Option.getOr(date.year)
                setExpirationDate(_ => Some({...date, year}))
              }}
            />
          </div>
        </>
      }}
      {switch creationDate {
      | None =>
        <button
          className="px-4 py-2 rounded border-2 border-sky-400 bg-sky-100 focus:outline-none hover:bg-sky-200 active:border-indigo-600 focus:bg-sky-200 font-semibold text-blue-800"
          type_="button"
          onClick={_ => setCreationDate(_ => ThisDate.empty()->Some)}>
          {"Add Creation Date"->React.string}
        </button>
      | Some(date) =>
        <>
          <button
            className="px-4 py-2 rounded border-2 border-sky-400 bg-sky-100 focus:outline-none hover:bg-sky-200 active:border-indigo-600 focus:bg-sky-200 font-semibold text-blue-800"
            type_="button"
            onClick={_ => setCreationDate(_ => None)}>
            {"Remove Creation Date"->React.string}
          </button>
          <div className="flex gap-3">
            <TextInput
              className="w-1/3"
              placeholder="Day"
              defaultValue={date.day->Int.toString}
              onInput={v => {
                let day = v->Int.fromString->Option.getOr(date.day)
                setCreationDate(_ => Some({...date, day}))
              }}
            />
            <TextInput
              className="w-1/3"
              placeholder="Month"
              defaultValue={date.month->Int.toString}
              onInput={v => {
                let month = v->Int.fromString->Option.getOr(date.month)
                setCreationDate(_ => Some({...date, month}))
              }}
            />
            <TextInput
              className="w-1/3"
              placeholder="Year"
              defaultValue={date.year->Int.toString}
              onInput={v => {
                let year = v->Int.fromString->Option.getOr(date.year)
                setCreationDate(_ => Some({...date, year}))
              }}
            />
          </div>
        </>
      }}
      <button
        type_="submit"
        className="px-4 py-2 rounded border-2 border-sky-400 bg-sky-300 focus:outline-none hover:bg-sky-500 active:border-indigo-600 focus:bg-sky-500 font-semibold text-blue-800 disabled:bg-gray-300 disabled:border-gray-300 disabled:text-gray-700"
        disabled={isLoading || isEnvError}>
        {"Submit"->React.string}
      </button>
      <button
        type_="reset"
        onClick={reset}
        className="px-4 py-2 rounded border-2 border-sky-400 bg-sky-100 focus:outline-none hover:bg-sky-200 active:border-indigo-600 focus:bg-sky-200 font-semibold text-blue-800"
        disabled={isLoading}>
        {"Clear"->React.string}
      </button>
    </form>
    <MessageBox status=state.status />
  </div>
}
