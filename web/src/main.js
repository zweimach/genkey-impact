import { Elm } from "./Main.elm";
import "./style.css";

if (import.meta.env === "development") {
  const ElmDebugTransform = await import("elm-debug-transformer");

  ElmDebugTransform.register({
    simple_mode: true,
  });
}

Elm.Main.init({
  flags: {
    apiUrl: import.meta.env["VITE_API_URL"],
  },
});
