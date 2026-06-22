#!/usr/bin/env bash
cd "$(dirname "$0")"
bash scripts/diagnose-local-vm.sh --repair
read -n 1 -s -r -p "Press any key to close…"
