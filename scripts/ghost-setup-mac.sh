#!/usr/bin/env bash
# Ghost Cloud one-shot on Mac — delegates to BenStudio if present.
set -euo pipefail

BEN_STUDIO="${HOME}/BenStudio"
FINISH="${BEN_STUDIO}/scripts/ghostcloud-remote/finish-setup.sh"

if [[ -x "$FINISH" ]] || [[ -f "$FINISH" ]]; then
  exec bash "$FINISH"
fi

echo "BenStudio Ghost Cloud scripts not found at $FINISH"
echo "Clone or copy ghostcloud-remote into BenStudio, then re-run."
exit 1
