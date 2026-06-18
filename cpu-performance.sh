#!/usr/bin/env bash
#
# cpu-performance.sh
# Define o governor do CPU como "performance" de forma persistente (via systemd).
#
# Uso:
#   sudo ./cpu-performance.sh          # aplica agora + instala serviço systemd
#   sudo ./cpu-performance.sh status   # mostra o governor atual de cada core
#   sudo ./cpu-performance.sh remove   # remove o serviço e restaura ondemand/powersave
#
# Requer: cpupower (linux-cpupower / linux-tools-common)

set -euo pipefail

SERVICE_NAME="cpu-performance"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

# --- helpers -------------------------------------------------------
red()    { printf '\033[1;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }

die() { red "ERRO: $*"; exit 1; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    die "Execute como root (sudo $0)"
  fi
}

require_cpupower() {
  if ! command -v cpupower &>/dev/null; then
    die "cpupower não encontrado. Instale com:\n" \
        "  Debian/Ubuntu:  sudo apt install linux-cpupower\n" \
        "  Arch:           sudo pacman -S cpupower\n" \
        "  Fedora:         sudo dnf install kernel-tools\n" \
        "  openSUSE:       sudo zypper install cpupower"
  fi
}

# --- comandos ------------------------------------------------------
cmd_apply() {
  require_root
  require_cpupower

  green "==> Aplicando governor 'performance' agora..."
  cpupower frequency-set -g performance || die "Falha ao definir governor."

  green "==> Criando serviço systemd ${SERVICE_NAME}..."
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Define CPU governor como performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set -g performance
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now "${SERVICE_NAME}.service" || die "Falha ao habilitar serviço."

  green "==> Pronto! Governor fixado em 'performance' (persistente após reboot)."
}

cmd_status() {
  require_cpupower
  echo "Governor atual por core:"
  cpupower frequency-info -p 2>/dev/null || true
  echo
  if command -v cpupower &>/dev/null; then
    local cur
    cur=$(cpupower frequency-info --policy 2>/dev/null | head -1 || true)
    echo "Política atual: ${cur:-desconhecida}"
  fi
  if systemctl is-enabled "${SERVICE_NAME}.service" &>/dev/null; then
    echo "Serviço systemd:   instalado e habilitado"
  else
    echo "Serviço systemd:   NÃO instalado"
  fi
}

cmd_remove() {
  require_root
  yellow "==> Removendo serviço ${SERVICE_NAME}..."
  systemctl disable --now "${SERVICE_NAME}.service" 2>/dev/null || true
  rm -f "$SERVICE_FILE"
  systemctl daemon-reload

  require_cpupower
  yellow "==> Voltando governor para ondemand (ou powersave)..."
  cpupower frequency-set -g ondemand 2>/dev/null \
    || cpupower frequency-set -g powersave 2>/dev/null \
    || cpupower frequency-set -g schedutil 2>/dev/null \
    || true

  green "==> Serviço removido. Governor restaurado."
}

# --- entrada -------------------------------------------------------
case "${1:-apply}" in
  apply)  cmd_apply  ;;
  status) cmd_status ;;
  remove) cmd_remove ;;
  -h|--help|help)
    echo "Uso: sudo $0 [apply|status|remove]"
    echo "  apply   – aplica performance agora + instala serviço systemd (padrão)"
    echo "  status  – exibe governor atual e status do serviço"
    echo "  remove  – remove serviço e restaura governor padrão"
    ;;
  *) die "Comando desconhecido: $1. Use apply, status ou remove." ;;
esac
