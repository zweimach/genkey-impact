import React from "@vitejs/plugin-react";
import ReScript from "@jihchi/vite-plugin-rescript";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [ReScript(), React()],
});
