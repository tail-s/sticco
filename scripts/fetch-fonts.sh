#!/usr/bin/env bash
# Downloads the free (SIL OFL 1.1) fonts used by Sticco's font themes from github.com/google/fonts
# into Resources/Fonts, which scripts/build-app.sh bundles into the app.
# Without them, every font theme still works using macOS fallback fonts.
set -euo pipefail
cd "$(dirname "$0")/.."
DEST=Resources/Fonts
mkdir -p "$DEST"

FAMILIES=(
  ibmplexsans ibmplexsanskr ibmplexsansjp   # Plex
  nunito gowundodum zenmarugothic           # Rounded
  patrickhand gaegu yomogi                  # Handwritten
  lora gowunbatang shipporimincho           # Serif
  jetbrainsmono nanumgothiccoding mplus1code # Mono
)

for fam in "${FAMILIES[@]}"; do
  echo "→ $fam"
  curl -fsSL "https://api.github.com/repos/google/fonts/contents/ofl/$fam" |
    python3 -c '
import json, sys
for f in json.load(sys.stdin):
    n = f["name"]
    if n.endswith(".ttf") and "Italic" not in n:
        print(f["download_url"])
' | while read -r url; do
      curl -fsSL "$url" -o "$DEST/$(basename "${url//%5B/[}" | sed 's/%5D/]/g; s/%2C/,/g')"
    done
  curl -fsSL "https://raw.githubusercontent.com/google/fonts/main/ofl/$fam/OFL.txt" -o "$DEST/OFL-$fam.txt" || true
done
echo "Fonts saved to $DEST"
