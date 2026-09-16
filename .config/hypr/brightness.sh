#!/usr/bin/env bash
# Ajusta o brilho dos monitores externos via DDC/CI (ddcutil).
# Uso: brightness.sh +5   ou   brightness.sh -5
set -euo pipefail

delta="${1:?uso: brightness.sh +5 ou -5}"

ddcutil detect --brief 2>/dev/null | grep -oP '(?<=Display )\d+' | while read -r n; do
    current=$(ddcutil --display "$n" getvcp 10 --brief 2>/dev/null | awk '{print $4}')
    [ -z "$current" ] && continue

    new=$((current + delta))
    [ "$new" -lt 0 ] && new=0
    [ "$new" -gt 100 ] && new=100

    ddcutil --display "$n" setvcp 10 "$new" 2>/dev/null || true
done
