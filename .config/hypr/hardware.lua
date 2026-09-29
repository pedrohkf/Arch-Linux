-- Configuração de hardware, compartilhada por TODOS os temas.
-- Não depende do tema ativo: monitores e teclado do ThinkPad.

-- ThinkPad T14s Gen 1: tela interna eDP-1.
-- Monitor externo plugado pega "preferred" e fica à direita automaticamente.
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

hl.config({
    input = {
        kb_layout  = "us,br",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
            tap_to_click   = true,
        },
    },
})

-- Trackpoint do ThinkPad (mouse externo: `hyprctl devices` pra achar o nome).
hl.device({
    name          = "elan-trackpoint",
    sensitivity   = 0,
    accel_profile = "adaptive",
})

-- Botões de janela estilo macOS (bolinhas vermelha/amarela/verde) via plugin
-- hyprbars (github.com/hyprwm/hyprland-plugins, instalado com hyprpm).
-- Guard com `if hl.plugin.hyprbars` porque se o plugin não recarregar depois
-- de um update do Hyprland (precisa `hyprpm reload` de novo), isso quebraria
-- o hyprland.lua inteiro sem o if.
if hl.plugin.hyprbars then
    hl.config({
        plugin = {
            hyprbars = {
                bar_height            = 32,
                bar_color             = "rgba(2e2e2eee)",
                bar_buttons_alignment = "left",
                bar_button_padding    = 8,
                bar_padding           = 10,
                bar_text_size         = 11,
                icon_on_hover         = true,
            },
        },
    })

    -- hyprctl dispatch clássico ("dispatch killactive") não funciona nessa
    -- build Lua do Hyprland — precisa passar a chamada Lua como string.
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(ff5f57)", fg_color = "rgb(4c0002)", size = 13, icon = "", action = [[hyprctl dispatch 'hl.dsp.window.close()']] })
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(febc2e)", fg_color = "rgb(915400)", size = 13, icon = "", action = [[hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:minimized" })']] })
    hl.plugin.hyprbars.add_button({ bg_color = "rgb(28c840)", fg_color = "rgb(006500)", size = 13, icon = "", action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized" })']] })
end
