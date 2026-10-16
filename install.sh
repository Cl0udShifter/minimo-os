#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
# Instalador do Minimo OS (Hyprland + minimo-shell) para Arch Linux.
# Uso:  ./install.sh [--dry-run] [--yes] [--preview]
#   ou: curl -fsSL https://raw.githubusercontent.com/$REPO_SLUG/main/install.sh | bash
#       (com opções: ... | bash -s -- --dry-run)
# Se não for executado a partir de uma cópia do repo, clona em ~/Projetos/minimo-os e
# executa a partir de lá. As perguntas são lidas de /dev/tty (funciona via pipe).
# É idempotente: pode ser executado novamente sem quebrar nada.
set -euo pipefail

REPO_SLUG="Cl0udShifter/minimo-os"
REPO_URL="https://github.com/$REPO_SLUG.git"
DEST="$HOME/Projetos/minimo-os"
TS=$(date +%Y%m%d-%H%M%S)

DRY=0; YES=0; PREVIEW=0
for a in "$@"; do
    case "$a" in
        --dry-run|-n) DRY=1 ;;
        --yes|-y) YES=1 ;;
        --preview) PREVIEW=1; DRY=1 ;;   # exibe a interface sem verificar ou alterar nada
        -h|--help) sed -n '2,5p' "$0" 2>/dev/null || true; exit 0 ;;
        *) echo "Opção desconhecida: $a" >&2; exit 2 ;;
    esac
done

# --- saída ---
if [ -t 1 ] || [ "$PREVIEW" = 1 ]; then
    B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; C=$'\e[36m'; D=$'\e[2m'; N=$'\e[0m'
else B=; G=; Y=; R=; C=; D=; N=; fi
TOTAL=7; STEP=0; WARNS=0; T0=$SECONDS
# Minimo e título com caracteres de densidade (mesmo algoritmo do terminal/minimo-hello)
HDR_MINIMO=( "         ......"
             "     .:++%%%%%%++:."
             "   .++\$\$\$\$\$\$\$\$\$\$\$\$++."
             "  :+%\$\$%+%\$\$\$\$%+%\$\$%+:"
             " :+%\$\$+   +\$\$+   +\$\$%+:"
             " :+\$\$\$+   +\$\$+   +\$\$\$+:"
             " :+\$\$\$+   +\$\$+   +\$\$\$+:"
             " :+%\$\$\$%+%\$\$\$\$%+%\$\$\$%+:"
             "  :+%\$\$\$\$\$\$\$\$\$\$\$\$\$\$%+:"
             "   .++\$\$\$\$\$\$\$\$\$\$\$\$++."
             "     .:++%%%%%%++:."
             "         ......" )
HDR_TITLE=( " .\$\$\$.   \$\$\$+ \$\$ +\$\$:   \$\$ +\$+ \$\$\$.   %\$\$%  +\$\$\$\$\$+      +\$\$\$\$\$%.  %\$\$%\$\$:"
            " .\$\$\$\$  +\$\$\$+ \$\$ +\$\$\$+  \$\$ +\$+ \$\$\$\$  :\$\$\$% \$\$:   :\$\$    %\$+   .\$\$.+\$%   ++"
            " .\$%+\$+.\$%+\$+ \$\$ +\$+:\$%.\$\$ +\$+ \$\$:\$% \$\$:\$%.\$\$     \$\$.   \$\$     %\$: +%\$\$\$%:"
            " .\$% %\$\$\$ +\$+ \$\$ +\$+ .\$\$\$\$ +\$+ \$\$ +\$\$\$.:\$% \$\$:   :\$\$    %\$+   .\$\$.:%.  .\$\$."
            " .\$% .\$\$: +\$+ \$\$ +\$+   %\$\$ +\$+ \$\$  \$\$+ :\$%  +\$\$\$\$\$+      +\$\$\$\$\$%. .%\$\$%\$\$+" )
header() {
    local cols=${COLUMNS:-$(tput cols 2>/dev/null || echo 80)} l
    printf '\n'
    for l in "${HDR_MINIMO[@]}"; do printf '   %s%s%s\n' "$B" "$l" "$N"; done
    printf '\n'
    if [ "$cols" -ge 82 ]; then for l in "${HDR_TITLE[@]}"; do printf '   %s%s%s\n' "$B" "$l" "$N"; done
    else printf '   %sM I N I M O   O S%s\n' "$B" "$N"; fi
    printf '\n   %sInstalador · Hyprland + minimo-shell · Arch Linux (PT-BR)%s\n' "$D" "$N"
    printf '   %s──────────────────────────────────────────────────────────%s\n' "$D" "$N"
}
step() {
    STEP=$((STEP+1))
    local bar="" i
    for ((i=1; i<=TOTAL; i++)); do if [ $i -le $STEP ]; then bar+="━"; else bar+="─"; fi; done
    printf '\n   %s%d/%d%s  %s%s%s  %s%s%s\n' "$D" "$STEP" "$TOTAL" "$N" "$B" "$*" "$N" "$D" "$bar" "$N"
}
substep() { printf '\n   %s···%s  %s%s%s\n' "$D" "$N" "$B" "$*" "$N"; }
ok()   { printf '        %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { WARNS=$((WARNS+1)); printf '        %s!%s %s\n' "$Y" "$N" "$*"; }
die()  { printf '\n        %s✗ %s%s\n\n' "$R" "$*" "$N" >&2; exit 1; }
# spin MSG CMD...: comando silencioso com indicador (apenas em terminal; nunca para sudo interativo)
spin() {
    local msg=$1; shift
    if [ "$DRY" = 1 ]; then printf '        %s○ %s%s\n' "$D" "$msg" "$N"; return 0; fi
    if [ ! -t 1 ]; then "$@" >/dev/null 2>&1 && ok "$msg" || { printf '        %s✗%s %s\n' "$R" "$N" "$msg"; return 1; }; return 0; fi
    "$@" >/dev/null 2>&1 & local pid=$! f='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    while kill -0 $pid 2>/dev/null; do printf '\r        %s%s%s %s' "$C" "${f:i++%10:1}" "$N" "$msg"; sleep 0.08; done
    if wait $pid; then printf '\r        %s✓%s %s\e[K\n' "$G" "$N" "$msg"
    else printf '\r        %s✗%s %s\e[K\n' "$R" "$N" "$msg"; return 1; fi
}
# run: executa (ou apenas exibe em --dry-run)
run() {
    if [ "$DRY" = 1 ]; then printf '        %s○ %s%s\n' "$D" "$*" "$N"
    else printf '        %s› %s%s\n' "$D" "$*" "$N"; "$@"; fi
}
confirm() {
    [ "$YES" = 1 ] && return 0
    [ "$DRY" = 1 ] && return 0
    local r; read -r -p "        $1 [S/n] " r </dev/tty || r=s
    case "${r,,}" in n|no|nao|não) return 1 ;; *) return 0 ;; esac
}
header

# --- verificações ---
step "Verificações"
if [ "$PREVIEW" = 1 ]; then ok "Arch Linux, usuário ${USER:-$(id -un)} (pré-visualização)"
else
    command -v pacman >/dev/null || die "Isto não parece o Arch Linux (falta o pacman)."
    [ "$(id -u)" -ne 0 ] || die "Não execute como root; use seu usuário comum (o sudo será solicitado)."
    command -v sudo >/dev/null || die "Falta o comando sudo."
    ok "Arch Linux, usuário $USER"
fi
[ "$DRY" = 1 ] && warn "Modo de teste: nada será alterado."

# --- repo: se não estiver rodando de dentro do repo, clonar ---
SELF_DIR=""
if [ -f "${BASH_SOURCE[0]:-}" ]; then SELF_DIR=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd); fi
if [ -n "$SELF_DIR" ] && [ -d "$SELF_DIR/minimo-shell" ] && [ -d "$SELF_DIR/hypr" ]; then
    REPO="$SELF_DIR"
else
    REPO="$DEST"
    substep "Repositório"
    if [ -d "$REPO/.git" ]; then
        ok "Já existe $REPO (git pull)"
        run git -C "$REPO" pull --ff-only || warn "Não foi possível atualizar; continuando com o conteúdo local."
    else
        command -v git >/dev/null || run sudo pacman -S --needed --noconfirm git
        run mkdir -p "$(dirname "$REPO")"
        if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
            run gh repo clone "$REPO_SLUG" "$REPO"
        else
            run git clone "$REPO_URL" "$REPO"
        fi
    fi
    # Continuar com o instalador do repo clonado
    if [ -f "$REPO/install.sh" ] && [ -z "${MINIMO_REEXEC:-}" ]; then
        ok "Continuando a partir de $REPO/install.sh"
        MINIMO_REEXEC=1 exec bash "$REPO/install.sh" "$@"
    fi
    if [ ! -d "$REPO/minimo-shell" ]; then
        [ "$DRY" = 1 ] && { warn "Em modo --dry-run não clonamos: o restante aparecerá após a clonagem real."; exit 0; }
        die "Não foi possível obter o repositório em $REPO."
    fi
fi
ok "Repositório: $REPO"

# --- pacotes (todos nos repositórios oficiais: extra) ---
PKGS=(
    hyprland xdg-desktop-portal-hyprland polkit-gnome hyprpolkitagent # compositor, portal, polkit
    quickshell qt6-declarative qt6-svg qt6-wayland             # shell (QtQuick, Effects, ícones SVG)
    pipewire pipewire-pulse wireplumber                        # áudio (PipeWire na shell)
    cava playerctl                                             # níveis de áudio (dança), teclas multimídia
    ghostty grim slurp wf-recorder zenity                      # terminal, capturas, gravação, seletor de fundo
    wl-clipboard cliphist                                      # área de transferência e histórico
    adwaita-fonts                                              # tipografia Adwaita Sans
    networkmanager                                             # Wi-Fi na ilha (nmcli)
    python                                                     # scripts da shell (cursor, status, workspaces)
    git gcc pkgconf polkit                                     # controle de versão e compilação do agente polkit nativo
)
OPTIONAL=(wl-clipboard github-cli)
step "Pacotes"
missing=()
for p in "${PKGS[@]}"; do { [ "$PREVIEW" = 0 ] && pacman -Q "$p" >/dev/null 2>&1; } || missing+=("$p"); done
if [ ${#missing[@]} -eq 0 ]; then ok "Todos os pacotes essenciais já estão instalados"
else
    warn "Pacotes necessários não encontrados: ${missing[*]}"
    if confirm "Deseja instalar com pacman?"; then run sudo pacman -S --needed --noconfirm "${PKGS[@]}"; else die "Instalação cancelada."; fi
fi
# Marcar como instalados explicitamente
deps=()
for p in "${PKGS[@]}"; do [ "$PREVIEW" = 0 ] && pacman -Qqd "$p" >/dev/null 2>&1 && deps+=("$p"); done
if [ ${#deps[@]} -gt 0 ]; then run sudo pacman -D --asexplicit "${deps[@]}"; fi
optmissing=()
for p in "${OPTIONAL[@]}"; do { [ "$PREVIEW" = 0 ] && pacman -Q "$p" >/dev/null 2>&1; } || optmissing+=("$p"); done
if [ ${#optmissing[@]} -gt 0 ]; then
    if confirm "Deseja instalar os pacotes opcionais (${optmissing[*]})?"; then run sudo pacman -S --needed --noconfirm "${optmissing[@]}"; fi
else ok "Pacotes opcionais instalados"; fi

# --- links ---
link() {
    local src=$1 dst=$2
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then ok "$dst"; return; fi
    run mkdir -p "$(dirname "$dst")"
    run ln -sfn "$src" "$dst"
}

step "Configuração do Hyprland"
HYPR="$HOME/.config/hypr"
needs_backup=0
if [ -e "$HYPR" ]; then
    while IFS= read -r -d '' f; do
        case "$f" in */monitores.lua) continue ;; esac
        [ -L "$f" ] && [[ "$(readlink -f "$f")" == "$REPO"/* ]] && continue
        needs_backup=1; break
    done < <(find "$HYPR" \( -type f -o -type l \) -name '*.lua' -print0)
fi
if [ "$needs_backup" = 1 ]; then
    run cp -a "$HYPR" "$HYPR.bak-$TS"
    ok "Backup criado: $HYPR.bak-$TS"
fi
link "$REPO/hypr/hyprland.lua" "$HYPR/hyprland.lua"
link "$REPO/hypr/minimo.lua"   "$HYPR/minimo.lua"
for f in "$REPO"/hypr/minimo/*.lua; do
    n=$(basename "$f")
    [ "$n" = monitores.lua ] && continue
    link "$f" "$HYPR/minimo/$n"
done
# Monitores: específico de cada PC → copia apenas se não existir.
MON="$HYPR/minimo/monitores.lua"
if [ -f "$MON" ] && [ ! -L "$MON" ]; then ok "$MON (mantendo a configuração deste PC)"
else
    [ -L "$MON" ] && run rm -f "$MON"
    run install -Dm644 "$REPO/hypr/minimo/monitores.lua" "$MON"
fi

step "Papéis de parede"
WALL=$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Imagens")/Wallpapers
run mkdir -p "$WALL"
for f in "$REPO"/assets/wallpapers/*; do
    [ -e "$WALL/$(basename "$f")" ] && { ok "$WALL/$(basename "$f")"; continue; }
    run cp "$f" "$WALL/"
done

step "Notificações e bandeja"
for d in mako dunst swaync; do
    if pgrep -x "$d" >/dev/null 2>&1; then warn "$d está em execução: feche-o e remova-o do autoarranque (a ilha do Minimo gerencia as notificações)."; fi
done
ok "As notificações são exibidas pela ilha"
for d in waybar snixembed; do
    if pgrep -x "$d" >/dev/null 2>&1; then warn "$d está em execução: pode competir pela bandeja do sistema (ícones em segundo plano)."; fi
done

step "Terminal: Ghostty + Minimo"
link "$REPO/terminal/minimo-hello" "$HOME/.local/bin/minimo-hello"
GCONF="$HOME/.config/ghostty/config"
if [ -e "$GCONF" ] && ! { [ -L "$GCONF" ] && [ "$(readlink -f "$GCONF")" = "$(readlink -f "$REPO/terminal/ghostty/config")" ]; }; then
    run mv "$GCONF" "$GCONF.bak-$TS"
    ok "Backup do Ghostty criado: $GCONF.bak-$TS"
fi
link "$REPO/terminal/ghostty/config" "$GCONF"
GTHEMES="$HOME/.config/ghostty/themes"
link "$REPO/terminal/ghostty/themes" "$GTHEMES"
add_hello() {
    local rc=$1 parent=$2
    [ -f "$rc" ] || { [ "$rc" = "$HOME/.bashrc" ] || return 0; }
    if grep -qs 'minimo-hello' "$rc"; then ok "$rc já possui a saudação"; return; fi
    local line="[[ \$- == *i* && \$(ps -o comm= -p \$PPID) != $parent ]] && [ -x ~/.local/bin/minimo-hello ] && ~/.local/bin/minimo-hello"
    if [ "$DRY" = 1 ]; then printf '        %s○ adicionar saudação em %s%s\n' "$D" "$rc" "$N"; return; fi
    printf '\n# Minimo te saúda ao abrir o terminal\n%s\n' "$line" >> "$rc"
    ok "Saudação adicionada em $rc"
}
add_hello "$HOME/.bashrc" bash
add_hello "$HOME/.zshrc" zsh

step "Serviço da shell e polkit (systemd --user)"
if [ -f "$REPO/minimo-shell/scripts/minimo-polkit-agent.c" ]; then
    substep "Compilando agente de autenticação Polkit do Minimo"
    run bash "$REPO/minimo-shell/scripts/polkit-agent.sh" --build || warn "Não foi possível compilar o agente nativo do Polkit; usando fallback do sistema."
fi
UNITS="$HOME/.config/systemd/user"
link "$REPO/systemd/minimo-shell.service" "$UNITS/minimo-shell.service"
link "$REPO/systemd/minimo-polkit.service" "$UNITS/minimo-polkit.service"
link "$REPO/systemd/minimo-clipboard.service" "$UNITS/minimo-clipboard.service"
link "$REPO/systemd/hyprland-session.target" "$UNITS/hyprland-session.target"
if [ "$REPO" != "$DEST" ]; then
    warn "O repositório não está em $DEST: certifique-se de manter o caminho sincronizado."
fi
run systemctl --user daemon-reload
run systemctl --user enable minimo-shell.service
run systemctl --user enable minimo-polkit.service
run systemctl --user enable minimo-clipboard.service
command -v gsettings >/dev/null && run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    run systemctl --user restart minimo-shell.service
    run systemctl --user restart minimo-polkit.service
    run systemctl --user restart minimo-clipboard.service
    run hyprctl reload
else
    ok "Será iniciado automaticamente ao entrar no Hyprland"
fi

el=$((SECONDS-T0))
printf '\n   %s──────────────────────────────────────────────────────────%s\n' "$D" "$N"
if [ "$DRY" = 1 ]; then printf '\n   %s✓ Teste concluído com sucesso.%s Nenhuma alteração foi feita no sistema.\n' "$B" "$N"
else printf '\n   %s%s✓ Minimo OS instalado com sucesso%s %sem %dm %02ds%s\n' "$G" "$B" "$N" "$D" $((el/60)) $((el%60)) "$N"; fi
[ "$WARNS" -gt 0 ] && printf '   %s! %d aviso(s) acima%s\n' "$Y" "$WARNS" "$N"
printf '\n   %sPróximo passo%s   Encerre a sessão atual e inicie o Hyprland\n' "$D" "$N"
printf   '   %sTerminal%s        Abra o Ghostty: o Minimo irá te saudar\n' "$D" "$N"
printf   '   %sRepositório%s     %s\n' "$D" "$N" "$REPO"
printf   '   %sDesinstalar%s     %s/uninstall.sh\n\n' "$D" "$N" "$REPO"
