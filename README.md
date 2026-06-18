# cpu-performance

Script em shell que define o governor da CPU como **performance** de forma
persistente — mesmo após reboot — usando um serviço **systemd**.

## O que ele faz

- Altera o governor de todos os cores para `performance` imediatamente.
- Cria e habilita um serviço `systemd` (`cpu-performance.service`) que
  reaplica o governor a cada boot.
- Fornece comandos para consultar o status e remover a configuração.

## Dependências

| Distro              | Pacote necessário       | Comando de instalação              |
| ------------------- | ----------------------- | ---------------------------------- |
| **Debian / Ubuntu** | `linux-cpupower`        | `sudo apt install linux-cpupower`  |
| **Arch Linux**      | `cpupower`              | `sudo pacman -S cpupower`          |
| **Fedora**          | `kernel-tools`          | `sudo dnf install kernel-tools`    |
| **openSUSE**        | `cpupower`              | `sudo zypper install cpupower`     |

> O comando `cpupower` precisa estar disponível no sistema.
> O script avisa e mostra o pacote correto caso ele não seja encontrado.

## Instalação e uso

```bash
# 1. Torne o script executável
chmod +x cpu-performance.sh

# 2. Aplique o governor performance (requer root)
sudo ./cpu-performance.sh

# 3. Verifique se está tudo certo
./cpu-performance.sh status
```

Exemplo de saída do `status`:

```
Governor atual por core:
  analyzing CPU 0:
    current policy: performance

Política atual: performance
Serviço systemd:   instalado e habilitado
```

## Comandos disponíveis

| Comando                       | Efeito                                          |
| ----------------------------- | ----------------------------------------------- |
| `sudo ./cpu-performance.sh`   | Aplica `performance` agora + instala serviço    |
| `./cpu-performance.sh status` | Mostra governor atual e status do serviço       |
| `sudo ./cpu-performance.sh remove` | Remove o serviço e restaura `ondemand`     |

## Como funciona a persistência

O script gera este arquivo de unidade do systemd:

```
/etc/systemd/system/cpu-performance.service
```

Com o seguinte conteúdo:

```ini
[Unit]
Description=Define CPU governor como performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set -g performance
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

- **`Type=oneshot`** — executa uma vez e conclui.
- **`RemainAfterExit=yes`** — o systemd considera o serviço "ativo" após a
  execução, facilitando verificações com `systemctl status`.
- **`WantedBy=multi-user.target`** — inicia junto com o sistema.

## Desfazendo

Para voltar ao governor padrão do sistema:

```bash
sudo ./cpu-performance.sh remove
```

Isso desabilita e remove o serviço, além de restaurar o governor para
`ondemand` (fallback para `powersave` ou `schedutil` se `ondemand` não
existir).

## Verificando manualmente

```bash
# Ver o governor atual
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Ver frequências disponíveis e governor suportados
cpupower frequency-info

# Ver status do serviço
systemctl status cpu-performance.service
```

## Por que performance?

- Elimina a latência de troca de frequência — o CPU fica na frequência
  máxima o tempo todo.
- Útil para servidores, workloads de baixa latência, benchmarks e jogos.
- **Atenção:** aumenta o consumo de energia e a temperatura. Em notebooks
  ou máquinas ociosas, considere usar apenas quando necessário.

## Licença

MIT — use, modifique e distribua livremente.
