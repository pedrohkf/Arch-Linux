#!/usr/bin/env bash
# Interface de terminal pra ajustar a velocidade do mouse HyperX (sem software oficial no Linux).
set -euo pipefail

HW_FILE="$HOME/.config/hypr/hardware.lua"

cur_sens=$(grep -oP '(?<=sensitivity   = )[-0-9.]+' "$HW_FILE")
cur_profile=$(grep -oP '(?<=accel_profile = ")[a-z]+' "$HW_FILE")

sens=$(whiptail --inputbox "Sensibilidade do mouse (-1.0 a 1.0)" 10 50 "$cur_sens" --title "Velocidade do mouse" 3>&1 1>&2 2>&3) || exit 0

if ! [[ "$sens" =~ ^-?(0(\.[0-9]+)?|1(\.0+)?)$ ]]; then
    whiptail --msgbox "Valor inválido: $sens (precisa ser entre -1.0 e 1.0)" 10 50
    exit 1
fi

profile=$(whiptail --menu "Perfil de aceleração" 12 50 2 \
    "flat" "1:1, sem curva (padrão gamer)" \
    "adaptive" "curva de aceleração do libinput" \
    --default-item "$cur_profile" 3>&1 1>&2 2>&3) || exit 0

sed -i \
    -e "s/sensitivity   = [-0-9.]\+/sensitivity   = $sens/" \
    -e "s/accel_profile = \"[a-z]\+\"/accel_profile = \"$profile\"/" \
    "$HW_FILE"

hyprctl reload >/dev/null

whiptail --msgbox "Aplicado: sensitivity=$sens, accel_profile=$profile" 10 50
