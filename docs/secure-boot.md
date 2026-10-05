# Secure Boot (GRUB + UKI + Windows em dual boot)

Status: **parado no meio, nada disso foi aplicado ainda.** Hoje o Secure Boot
fica **desligado** e o Arch/GRUB bootam normalmente. Este arquivo tem o
diagnóstico e o plano pra retomar. Pendência resumida em [TODO.md](TODO.md).

## Sintoma

Com o Secure Boot **ligado** na BIOS, o PC só mostra o Windows: o GRUB e o Arch
não aparecem.

## Causa

Os arquivos do Arch **já estão assinados** com as chaves do `sbctl`
(`sudo sbctl verify`, ver abaixo), mas essas chaves **nunca foram enroladas no
firmware**: o Setup Mode está desligado, então a BIOS ainda só confia nas
chaves de fábrica. Com o Secure Boot ligado ela recusa o GRUB e o UKI e cai no
próximo item da `BootOrder`, que é o Windows Boot Manager (assinado pela
Microsoft). O Windows não está quebrado; falta enrolar as chaves.

> Correção: numa primeira versão desta doc eu disse que o GRUB/UKI não estavam
> assinados e que não existiam chaves. Errado — o `sbctl verify` do
> 2026-09-21 mostra tudo assinado e as chaves existem desde 2026-09-18
> (`/var/lib/sbctl`).

## Estado da máquina (2026-09-21)

- `sbctl 0.18` instalado, **chaves já criadas** (`/var/lib/sbctl/keys`,
  2026-09-18) mas **não enroladas**. `sbctl status`: Secure Boot desligado,
  **Setup Mode desligado** (as chaves de fábrica ainda estão gravadas — não dá
  pra enrolar as suas até limpar isso na BIOS), vendor keys: microsoft.
- `sudo sbctl verify` (2026-09-21): **assinados** `/boot/EFI/BOOT/BOOTX64.EFI`,
  `/boot/EFI/Linux/arch-linux.efi`, `/boot/vmlinuz-linux`,
  `/boot/EFI/ARCH/GRUBX64.EFI`. **Não assinados**: `/boot/grub/x86_64-efi/core.efi`
  e `grub.efi` — são artefatos do `grub-install`, não são alvo de boot; se o
  `verify` incomodar, `sudo sbctl remove-file` neles.
- Firmware: AMI 5.17, UEFI 2.70.
- Discos separados, cada um com a própria ESP:
  - Arch: `sdb1` (1G, vfat) montado em `/boot`; `sdb2` = `/`, `sdb3` = `/home`
  - Windows: `sda1` (ESP do Windows), `sda2`/`sda3` NTFS
- `BootOrder`: `0000` (ARCH → `\EFI\ARCH\GRUBX64.EFI`), `0004` (UEFI OS →
  `\EFI\BOOT\BOOTX64.EFI`, mesma ESP do Arch), `0003` (Windows Boot Manager).
- Bootloader: GRUB 2.14 (`os-prober` ligado, tema `CyberRe`). O kernel sobe
  via **UKI** (`/boot/EFI/Linux/arch-linux.efi`; o preset do `mkinitcpio`
  também declara um `fallback_uki`, mas ele **não existe** em disco hoje); o
  GRUB chama o UKI pelo `/etc/grub.d/15_uki`.
- `shim-signed` **não** está instalado (o plano abaixo é sem shim, só `sbctl`).

## Plano

### 1. BIOS (físico)

Secure Boot → modo *Custom* → apagar as chaves (*Clear / Delete all Secure Boot
keys*, ou *Reset to Setup Mode*). Deixar o Secure Boot **desligado** ainda e
voltar pro Arch. Conferir:

```bash
sbctl status   # Setup Mode: Enabled
```

### 2. Enrolar as chaves

As chaves já existem (não rodar `create-keys` de novo, senão os arquivos
assinados hoje perdem a validade). O `--microsoft` é **obrigatório**: sem ele o
Windows deixa de bootar.

```bash
sudo sbctl enroll-keys --microsoft
```

### 3. Conferir o GRUB (parte ainda não verificada)

> Sem shim, o GRUB com Secure Boot ligado bloqueia `insmod` de módulos
> externos. O tema, o `os-prober` e a troca de vídeo usam vários (`gfxterm`,
> `png`, `chain`...). Se o GRUB atual foi instalado sem `--disable-shim-lock`
> e sem esses módulos embutidos no core, ele pode abrir e falhar no menu.
> **Ainda não foi checado como o GRUB atual foi instalado.** Checar antes de
> ligar o Secure Boot.

Checagem (pendente — só rodar `sudo` na mão, o `/boot` é fechado pro usuário):

```bash
sudo ls -l /boot/EFI/ARCH/
sudo strings /boot/EFI/ARCH/GRUBX64.EFI | grep -c -i -E "gfxterm|png|chain"
```

Contagem > 0 sugere que os módulos estão embutidos no core; 0 sugere que não
(precisa reinstalar, abaixo). É só um indício, não uma prova.

Se precisar reinstalar (a lista de módulos é o que falta definir):

```bash
sudo grub-install --target=x86_64-efi --efi-directory=/boot \
  --bootloader-id=ARCH --disable-shim-lock \
  --modules="part_gpt part_msdos <resto da lista>"
sudo sbctl sign -s /boot/EFI/ARCH/GRUBX64.EFI   # reassinar após reinstalar
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
```

`grub-install --help` confirma `--disable-shim-lock` e `--modules`. O hook
`zz-sbctl.hook` reassina os arquivos do banco a cada atualização de pacote.

### 4. Assinatura

Já feita (ver `sbctl verify` acima). Só repetir `sudo sbctl verify` depois de
qualquer reinstalação do GRUB ou regeneração do UKI.

### 5. Ligar o Secure Boot e testar

Ligar na BIOS e dar boot. **Windows** (assinado pela Microsoft, chaves dela
enroladas no passo 2) e **Arch** devem aparecer.

## Próximo passo (2026-09-21)

1. Rodar a checagem do GRUB (passo 3) e ver o resultado.
2. BIOS: limpar as chaves (Setup Mode) com o Secure Boot ainda desligado.
3. `sudo sbctl enroll-keys --microsoft`, ligar o Secure Boot e testar.

## Se der erro

- **Só o Windows aparece / o Arch some:** desligue o Secure Boot na BIOS; o Arch
  volta a bootar como hoje. Depois rode `sudo sbctl verify` e veja o que ficou
  sem assinatura.
- **Windows parou de bootar:** as chaves da Microsoft não foram enroladas
  (faltou `--microsoft`). Desligue o Secure Boot, limpe as chaves na BIOS e
  refaça o passo 2.
- **GRUB abre mas dá erro de módulo / "prohibited by secure boot policy":**
  faltou embutir algum módulo no core (passo 3). Reinstale com a lista
  completa.
- **Sem acesso gráfico:** `Ctrl+Alt+F3` abre um TTY; o desfazer mais seguro é
  sempre desligar o Secure Boot na BIOS.

## Alternativa considerada

Trocar o GRUB por **systemd-boot** (mais simples com UKI). Descartado por
enquanto: ele só enxerga o Windows se estiver na *mesma* ESP, e aqui o Windows
está em outro disco (`sda1`), então perderia a entrada do Windows no menu.
