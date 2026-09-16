# Melhorias futuras

Coisas que ficaram pendentes ou poderiam ficar melhores no setup do
[Hyprland + Modus](hyprland-modus-setup.md). Fica aqui pra não perder o fio.

## Pendente

- [ ] **Samsung LF24T35 não responde DDC/CI** (`ddcutil` dá "communication
  failed" nela, só a LG UltraGear funciona). Provavelmente tem uma opção
  "DDC/CI" desligada no menu OSD físico do monitor — precisa testar com o
  monitor na mão.
- [ ] **Painel de histórico de notificações do Modus** tem um bug de
  renderização: abre de verdade por baixo dos panos (estado, camada Wayland
  com tamanho/posição corretos) mas não desenha nada visível na tela, mesmo
  com fundo sólido no CSS. Provavelmente bug de composição GTK/Wayland mais
  fundo no código deles — precisaria de GTK Inspector ao vivo pra debugar
  direito. O toast normal (aviso que aparece e some) funciona bem, só o
  histórico que não.
- [ ] **Secure Boot** — parou no meio: já instalado `sbctl`, falta resetar a
  firmware pra Setup Mode (precisa mexer na BIOS fisicamente), gerar/enrolar
  as chaves com `--microsoft` (senão o Windows para de bootar), e assinar
  GRUB + UKI.

## Ideias / não crítico

- [ ] Posição do widget de player de música (`~/.config/modus-desktop-widgets/player.py`)
  ainda tá "no olho" — dar uma organizada fina no layout dos widgets de
  desktop (relógio/clima/calendário/RAM/CPU/player) pra não sobrepor em
  resoluções diferentes.
- [ ] Automatizar o patch dos arquivos do Modus (`.config/hypr/modus-patches/`)
  em vez de reaplicar na mão depois de um `git pull` no repo deles — talvez
  um script `apply-patches.sh` que copia os arquivos modificados por cima da
  instalação.
- [ ] Testar o setup inteiro num monitor único / notebook (foi construído e
  testado só com 2 monitores externos, um deles rotacionado).

## Descoberto mas não documentado a fundo

- O `theme-switch.sh` mata processos "conhecidos" (waybar, modus, dock) antes
  de trocar de tema — se um tema novo subir algum processo que o script não
  sabe matar, pode sobrar órfão até o próximo boot (foi assim que achamos o
  bug do waybar duplicado original). Vale revisar essa lista sempre que um
  tema novo for adicionado.
