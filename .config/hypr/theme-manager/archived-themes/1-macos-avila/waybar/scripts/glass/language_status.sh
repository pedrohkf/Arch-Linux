#!/usr/bin/env bash
# Imprime o layout de teclado ativo como US ou BR para o módulo custom/language
layout=$(hyprctl devices -j | python3 -c "
import json, sys
d = json.load(sys.stdin)
for kb in d['keyboards']:
    if kb['name'] == 'evision-rgb-keyboard':
        print(kb['active_keymap'])
        break
")

case "$layout" in
    *Portuguese*|*Brazil*) echo "BR" ;;
    *) echo "US" ;;
esac
