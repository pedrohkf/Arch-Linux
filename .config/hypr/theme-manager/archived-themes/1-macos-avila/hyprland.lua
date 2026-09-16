-- Tema "macOS" — adaptado de github.com/AvilaCarlosDev/hyprland-macos-dotfiles
-- Ajustes feitos: removido tudo específico do autor original (teclado
-- ThinkPad, brave, shimeji, monitor virtual via wayvnc), rofi trocado por
-- wofi (já instalado), e monitores/teclado vêm de hardware.lua (compartilhado).

require("hardware")

local terminal    = "kitty"
local fileManager = "nautilus"
local menu        = "~/.config/waybar/scripts/launcher-menu.sh"
local mainMod     = "SUPER"

hl.on("hyprland.start", function()
    hl.exec_cmd([[sh -lc 'wall="$(cat ~/.config/hypr/current_wallpaper 2>/dev/null || echo ~/wallpaper/nature.jpg)"; pkill swaybg 2>/dev/null; swaybg -i "$wall" -m fill &']])
    hl.exec_cmd("swaync")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("~/.config/waybar/scripts/weather.sh > /dev/null 2>&1 &")
    hl.exec_cmd([[sh -lc 'exec 9>/tmp/waybar-supervisor.lock; flock -n 9 || exit 0; while true; do waybar; sleep 3; done']])
    hl.exec_cmd("nwg-dock-hyprland -p bottom -i 44 -mb 8 -ml 12 -mr 12 -nolauncher -l overlay -d -hd 100")
    hl.exec_cmd("~/.config/hypr/scripts/layout-signal.py &")
end)

-- Cursor "McMojave-cursors": instale o tema separadamente pra isso valer
-- (github.com/vinceliuice/McMojave-cursors); sem ele cai no cursor padrão.
hl.env("XCURSOR_THEME", "McMojave-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "McMojave-cursors")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 0,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(ffffffaa)", "rgba(c0c0c0aa)" }, angle = 45 },
            inactive_border = "rgba(00000044)",
        },
        layout = "dwindle",
        resize_on_border = true,
    },

    decoration = {
        rounding = 14,
        active_opacity = 0.96,
        inactive_opacity = 0.88,
        blur = {
            enabled = true,
            size = 8,
            passes = 4,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
            noise = 0.02,
            contrast = 1.0,
            brightness = 1.0,
            vibrancy = 0.25,
        },
        shadow = {
            enabled = true,
            range = 30,
            render_power = 3,
            color = "rgba(00000088)",
            offset = { 0, 8 },
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = "0x111111",
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        focus_on_activate = true,
    },
})

hl.curve("macIn", { type = "bezier", points = { { 0.32, 0.72 }, { 0, 1 } } })
hl.curve("macOut", { type = "bezier", points = { { 0.42, 0 }, { 0.58, 1 } } })
hl.curve("bounce", { type = "bezier", points = { { 0.5, 1.5 }, { 0.5, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "macIn", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "macOut", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "macIn" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "macIn", style = "slide" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "macIn", style = "fade" })

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.window_rule({
    name = "float-dialogs",
    match = { class = "^(pavucontrol|nm-connection-editor|blueman-manager)$" },
    float = true,
})

hl.window_rule({
    name = "float-pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin = true,
})

hl.window_rule({
    name = "opacity-terminals",
    match = { class = "^(kitty|Alacritty|wezterm)$" },
    opacity = "0.92 0.85",
})

hl.window_rule({
    name = "opacity-filemanagers",
    match = { class = "^(thunar|nautilus|org\\.gnome\\.Nautilus)$" },
    opacity = "0.95 0.90",
})

hl.layer_rule({
    name = "blur-swaync-cc",
    match = { namespace = "swaync-control-center" },
    blur = true,
    ignore_alpha = true,
})

hl.layer_rule({
    name = "blur-swaync-notif",
    match = { namespace = "swaync-notification-window" },
    blur = true,
})

hl.layer_rule({
    name = "blur-waybar",
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = true,
})

hl.layer_rule({
    name = "blur-nwg-dock",
    match = { namespace = "nwg-dock" },
    blur = true,
    ignore_alpha = true,
})

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd([[cliphist list | wofi --dmenu -p "Clipboard" | cliphist decode | wl-copy]]))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))
hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
hl.bind("CTRL + F8", hl.dsp.exec_cmd("~/.config/hypr/scripts/select-wallpaper.sh"))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { drag = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { drag = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

hl.bind("XF86Display", hl.dsp.exec_cmd("nwg-displays"))
hl.bind("XF86NotificationCenter", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind("XF86Favorites", hl.dsp.exec_cmd([[bash -c 'rfkill list bluetooth | grep -q "Soft blocked: yes" && rfkill unblock bluetooth || rfkill block bluetooth']]))

-- Trocador de temas (funciona em qualquer tema)
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.config/hypr/theme-manager/theme-menu.sh"))
hl.bind(mainMod .. " + equal", hl.dsp.exec_cmd("kitty -e ~/.config/hypr/mouse-speed.sh"))
