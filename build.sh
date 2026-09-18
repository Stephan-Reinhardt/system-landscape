#!/usr/bin/env bash

set -euo pipefail

SRC="${1:-model.json}"
HTML="${2:-landscape.html}"

[ -f "$SRC" ]  || { echo "missing: $SRC";  exit 1; }
[ -f "$HTML" ] || { echo "missing: $HTML"; exit 1; }

# Validate JSON before generating anything
node -e "JSON.parse(require('fs').readFileSync('$SRC','utf8'))" \
  || { echo "$SRC is not valid JSON"; exit 1; }

# model.js
{
  printf '// Generated from %s - do not edit directly.\n' "$SRC"
  printf 'window.LANDSCAPE_MODEL = '
  cat "$SRC"
  printf ';\n'
} > model.js

# landscape-standalone.html: model.js inlined so the page renders without other files
node -e '
const fs = require("fs");
const html = fs.readFileSync(process.argv[1], "utf8");
const json = fs.readFileSync(process.argv[2], "utf8");
const inline = "<script>window.LANDSCAPE_MODEL = " + json + ";<\/script>";
const out = html.replace(/<script src="model\.js"><\/script>/, () => inline);
if (out === html) { console.error("script tag for model.js not found"); process.exit(1); }
fs.writeFileSync("landscape-standalone.html", out);
' "$HTML" "$SRC"

printf 'generated: model.js (%s), landscape-standalone.html (%s)\n' \
  "$(wc -c < model.js | tr -d ' ')" "$(wc -c < landscape-standalone.html | tr -d ' ')"
