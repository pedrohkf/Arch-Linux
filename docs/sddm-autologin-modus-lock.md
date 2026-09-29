# Tela de login = lock do Modus (SDDM autologin)

> **ThinkPad:** trocar de `cosmic-greeter` pra SDDM: `sudo systemctl disable cosmic-greeter && sudo systemctl enable sddm`
> (nunca `start` na sessão ativa). Os hooks (`Super+L`, lock ao subir, `hyprpm reload`) agora vivem em
> `themes/1-macos/hyprland.lua` — o `theme-switch.sh` sobrescreve o `hyprland.lua`, então o que não estiver no tema some.

Anotação pra quando algo der errado no boot/lock. Contexto do setup geral em
[hyprland-modus-setup.md](hyprland-modus-setup.md).

## O que foi feito e por quê

A tela de login que aparecia ao ligar o PC era o **SDDM sem tema** (feia).
O lock do Modus não pode *ser* o SDDM: o SDDM roda antes do login e o lock do
Modus é um *session lock* (`gtk-session-lock`) que só existe dentro de uma
sessão Wayland já aberta. Solução: o SDDM entra sozinho (autologin) e o
Hyprland tranca a sessão com o lock do Modus assim que sobe. Na prática, a
"tela de login" passa a ser a do Modus.

São 3 peças:

1. **`/etc/sddm.conf.d/autologin.conf`** (fora do repo, precisa de sudo):

   ```ini
   [Autologin]
   User=elliot
   Session=hyprland-uwsm
   ```

   `hyprland-uwsm` é a mesma sessão que o SDDM já usava
   (`uwsm start -e -D Hyprland hyprland.desktop`). Sessões disponíveis:
   `ls /usr/share/wayland-sessions/`.

2. **Lock ao subir o Hyprland** — em `~/.config/hypr/hyprland.lua`:

   ```lua
   hl.on("hyprland.start", function()
       hl.exec_cmd("cd " .. os.getenv("HOME") .. "/.config/Modus && uv run python start.py lock")
   end)
   ```

   `start.py lock` é um processo separado (`window.lock:main`), então não
   depende do Modus principal já ter subido.

3. **`Super + L` volta a trancar** — também em `hyprland.lua`:

   ```lua
   hl.bind("SUPER + L", hl.dsp.exec_cmd('fabric-cli exec modus "lock_screen.lock()"'))
   ```

## Se der erro

**Boot caiu numa sessão aberta, sem tela de senha** (o lock não subiu):
`Super + L` tranca na hora. Pra ver por que falhou, rode na mão:
`cd ~/.config/Modus && uv run python start.py lock`.

**Quero voltar ao login normal do SDDM:**

```bash
sudo rm /etc/sddm.conf.d/autologin.conf
```

(e remova o bloco `hl.on("hyprland.start", ... start.py lock ...)` do
`hyprland.lua`, senão a sessão tranca sozinha ao logar.)

**Sem tela gráfica / travou no boot:** `Ctrl+Alt+F3` abre um TTY; de lá dá pra
apagar o `autologin.conf` acima.

**Só quero um SDDM mais bonito** (sem autologin): instalar um tema, ex.
`sddm-astronaut-theme`, e apontar `[Theme] Current=` em
`/etc/sddm.conf.d/`. Não é a tela do Modus, só parecida.

## Ressalvas

- Com autologin, se o disco **não** for criptografado, há alguns segundos de
  sessão aberta entre o Hyprland subir e o lock aparecer.
- Se o lock falhar ao subir, a sessão fica aberta sem senha (ver acima).
- O boot completo (SDDM → autologin → lock) **não foi testado** quando isto
  foi escrito; só o `Super + L` foi.

## Descobertas (pra não repetir a investigação)

- O README do Modus diz `Super + L` = lock e "bind: `uv run lock`", mas isso
  **não vale** aqui: o `config/hypr/modus.lua` só liga **`Super + Ctrl + L`**
  (`lock_screen.lock()` via `fabric-cli exec modus`). O `Super + L` era do
  `hyprlock` antes do Modus (ver
  `~/.config/hypr/backup-pre-modus-*/hyprland.lua`) e ficou sem bind.
- O comando que funciona pro lock é
  `fabric-cli exec modus "lock_screen.lock()"` (ou direto
  `uv run python start.py lock` dentro de `~/.config/Modus`). `uv run lock`
  do README não é o caminho aqui.
- `fabric-cli exec <app> ...` retorna exit code 1 se o app não estiver
  rodando ("couldn't find a running Fabric instance").
- A tela de bloqueio "do Hyprland" é o `hyprlock` (instalado, mas sem
  `hyprlock.conf`). O `hypridle.conf` do Modus (`lock_cmd`) já usa o lock do
  Modus, não o `hyprlock`.
