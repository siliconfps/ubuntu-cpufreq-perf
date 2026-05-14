#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, execute como root (use sudo)."
  exit
fi

# Verifica se o cpufrequtils está instalado
if ! command -v cpufreq-set &> /dev/null; then
    echo "cpufrequtils não encontrado. Instalando..."
    apt update && apt install -y cpufrequtils
fi

# Obtém o número de cores (lógicos)
nproc=$(nproc)

echo "Configurando $nproc núcleos para o modo performance..."

# Aplica o modo performance a cada core
for ((i=0; i<nproc; i++)); do
    cpufreq-set -c $i -g performance
done

echo "Concluído! Verificando status atual:"
cpufreq-info | grep "current CPU frequency" | head -n $nproc
