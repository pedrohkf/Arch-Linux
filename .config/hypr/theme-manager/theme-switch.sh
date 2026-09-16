#!/usr/bin/env bash
# Troca o tema ativo do Hyprland/Waybar.
# Uso: theme-switch.sh <numero-ou-nome-da-pasta-em-themes/>
set -euo pipefail

HYPR_DIR="$HOME/.config/hypr"
THEMES_DIR="$HYPR_DIR/themes"
STATE_FILE="$HYPR_DIR/current-theme"

list_themes() {
    find "$THEMES_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort
}

if [ $# -eq 0 ]; then
    echo "Temas disponíveis:"
    list_themes
    echo
    echo "Atual: $(cat "$STATE_FILE" 2>/dev/null || echo '?')"
    echo "Uso: $0 <numero-ou-nome>"
    exit 0
fi

pick="$1"
target=""
for d in $(list_themes); do
    id="${d%%-*}"
    if [ "$id" = "$pick" ] || [ "$d" = "$pick" ]; then
        target="$d"
        break
    fi
done

if [ -z "$target" ]; then
    echo "Tema '$pick' não encontrado." >&2
    list_themes >&2
    exit 1
fi

THEME_DIR="$THEMES_DIR/$target"

cp "$THEME_DIR/hyprland.lua" "$HYPR_DIR/hyprland.lua"

rm -rf "$HYPR_DIR/scripts"
if [ -d "$THEME_DIR/scripts" ]; then
    cp -r "$THEME_DIR/scripts" "$HYPR_DIR/scripts"
    find "$HYPR_DIR/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
fi

rm -rf "$HOME/.config/waybar"
if [ -d "$THEME_DIR/waybar" ]; then
    cp -r "$THEME_DIR/waybar" "$HOME/.config/waybar"
    find "$HOME/.config/waybar" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
fi

echo "$target" > "$STATE_FILE"

# Mata tudo que algum tema possa ter deixado rodando ANTES do reload, pra não
# competir com o autostart do tema novo (mesma classe de bug do waybar duplicado).
pkill waybar 2>/dev/null || true
pkill nwg-dock-hyprland 2>/dev/null || true
killall modus 2>/dev/null || true
sleep 0.3

hyprctl reload

# hl.on("hyprland.start", ...) só dispara no boot de verdade da sessão, NUNCA
# em hyprctl reload — então quem inicia os processos do tema é este script,
# sempre explícito, nunca dependendo do autostart do hyprland.lua disparar de novo.
if [ -d "$THEME_DIR/waybar" ]; then
    setsid waybar >/tmp/waybar.log 2>&1 &
    disown
fi

if grep -q "Modus/config/hypr/modus.lua" "$THEME_DIR/hyprland.lua" 2>/dev/null; then
    MODUS_DIR="$HOME/.config/Modus"

    # Réplica dos comandos do hl.on("hyprland.start", ...) do modus.lua — esse
    # hook nunca dispara em reload, então cada um deles precisa ser subido
    # explicitamente aqui, igual o start.py. Todos guardados por pgrep pra não
    # duplicar se o tema for trocado de novo antes do reboot.
    (pgrep -x awww-daemon >/dev/null || setsid uwsm app -- awww-daemon >/tmp/awww.log 2>&1 &)
    (pgrep -f "wl-paste --type text --watch cliphist" >/dev/null || setsid wl-paste --type text --watch cliphist store >/dev/null 2>&1 &)
    (pgrep -f "wl-paste --type image --watch cliphist" >/dev/null || setsid wl-paste --type image --watch cliphist store >/dev/null 2>&1 &)
    (pgrep -x hypridle >/dev/null || setsid uwsm app -- hypridle >/tmp/hypridle.log 2>&1 &)

    (
        flock /tmp/modus-guard.lock -c \
            "pgrep -x modus >/dev/null || (cd '$MODUS_DIR' && uwsm app -- uv run python start.py)"
    ) >/tmp/modus.log 2>&1 &
    disown
fi

notify-send "Tema" "Ativado: $target" 2>/dev/null || echo "Tema ativado: $target"
