#!/bin/bash
# ====================================================================
# Ubuntu CPU Performance - Modo Performance Permanente via systemd
# Uso:
#   1. Extraia todos os arquivos para a mesma pasta
#   2. Execute:  sudo ./set_performance.sh
# ====================================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo "ERRO: Execute como root (sudo)."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ">>> Instalando cpufreq-perf (modo performance permanente) <<<"

# 1. Copia o script worker (grava direto no sysfs, zero dependencias)
cp "$SCRIPT_DIR/cpufreq-perf.sh" /usr/local/bin/cpufreq-perf.sh
chmod +x /usr/local/bin/cpufreq-perf.sh

# 2. Copia a unidade systemd
cp "$SCRIPT_DIR/cpufreq-perf.service" /etc/systemd/system/cpufreq-perf.service

# 3. Recarrega, habilita no boot e inicia agora
systemctl daemon-reload
systemctl enable cpufreq-perf.service --now

echo ""
echo "============================================"
echo "  SERVICO INSTALADO E EM EXECUCAO"
echo "  O governor 'performance' sera aplicado"
echo "  automaticamente a cada boot."
echo "============================================"
echo ""

systemctl status cpufreq-perf.service --no-pager -l || true

echo ""
echo "Governors atuais:"
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort -u || echo "(nao disponivel)"