import { defineConfig } from "vite";
import Elm from "vite-plugin-elm";

export default defineConfig({
  plugins: [Elm()],
});
