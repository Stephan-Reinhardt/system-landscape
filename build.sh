#!/usr/bin/env bash

set -euo pipefail

SRC="${1:-model.json}"
HTML="${2:-landscape.html}"

[ -f "$SRC" ]  || { echo "fehlt: $SRC";  exit 1; }
[ -f "$HTML" ] || { echo "fehlt: $HTML"; exit 1; }

# JSON validieren, bevor irgendetwas erzeugt wird
node -e "JSON.parse(require('fs').readFileSync('$SRC','utf8'))" \
  || { echo "$SRC ist kein gueltiges JSON"; exit 1; }

# model.js
{
  printf '// Automatisch erzeugt aus %s - nicht direkt bearbeiten.\n' "$SRC"
  printf 'window.LANDSCAPE_MODEL = '
  cat "$SRC"
  printf ';\n'
} > model.js

# landscape-standalone.html
node -e '
const fs = require("fs");
const html = fs.readFileSync(process.argv[1], "utf8");
const json = fs.readFileSync(process.argv[2], "utf8");
const inline = "<script>window.LANDSCAPE_MODEL = " + json + ";<\/script>";
const out = html.replace(/<script src="model\.js"><\/script>/, inline);
if (out === html) { console.error("script-Tag fuer model.js nicht gefunden"); process.exit(1); }
fs.writeFileSync("landscape-standalone.html", out);
' "$HTML" "$SRC"

printf 'erzeugt: model.js (%s), landscape-standalone.html (%s)\n' \
  "$(wc -c < model.js | tr -d ' ')" "$(wc -c < landscape-standalone.html | tr -d ' ')"
