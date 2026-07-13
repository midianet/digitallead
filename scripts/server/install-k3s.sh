cat > scripts/server/install-k3s.sh <<'EOF'
#!/usr/bin/env bash

set -Eeuo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION_FILE="${REPOSITORY_ROOT}/infrastructure/k3s/version.env"
CONFIG_SOURCE="${REPOSITORY_ROOT}/infrastructure/k3s/config.yaml"
CONFIG_TARGET="/etc/rancher/k3s/config.yaml"
INSTALLER_FILE="/tmp/install-k3s.sh"

log() {
  printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

fail() {
  printf '\nERRO: %s\n' "$1" >&2
  exit 1
}

if [[ "${EUID}" -ne 0 ]]; then
  fail "Execute este script com sudo."
fi

[[ -f "${VERSION_FILE}" ]] ||
  fail "Arquivo de versão não encontrado: ${VERSION_FILE}"

[[ -f "${CONFIG_SOURCE}" ]] ||
  fail "Configuração do K3s não encontrada: ${CONFIG_SOURCE}"

# shellcheck disable=SC1090
source "${VERSION_FILE}"

[[ -n "${K3S_VERSION:-}" ]] ||
  fail "K3S_VERSION não foi definida."

if systemctl list-unit-files k3s.service >/dev/null 2>&1; then
  fail "O serviço k3s já existe. A instalação foi interrompida para evitar sobrescrita."
fi

log "Validando hostname"
CURRENT_HOSTNAME="$(hostname)"

if [[ "${CURRENT_HOSTNAME}" != "dl-platform-01" ]]; then
  fail "Hostname atual é '${CURRENT_HOSTNAME}', esperado 'dl-platform-01'."
fi

log "Instalando configuração declarativa"
install -d -o root -g root -m 700 /etc/rancher/k3s

install \
  -o root \
  -g root \
  -m 600 \
  "${CONFIG_SOURCE}" \
  "${CONFIG_TARGET}"

log "Baixando instalador oficial do K3s"
curl \
  --fail \
  --silent \
  --show-error \
  --location \
  https://get.k3s.io \
  --output "${INSTALLER_FILE}"

chmod 700 "${INSTALLER_FILE}"

log "Instalando K3s ${K3S_VERSION}"
INSTALL_K3S_VERSION="${K3S_VERSION}" \
INSTALL_K3S_EXEC="server" \
  "${INSTALLER_FILE}"

log "Aguardando o serviço K3s"
systemctl is-enabled k3s
systemctl is-active --quiet k3s

log "Aguardando o nó ficar Ready"
for attempt in $(seq 1 60); do
  if k3s kubectl get node dl-platform-01 \
      --no-headers 2>/dev/null |
      grep -q ' Ready'; then
    log "Nó dl-platform-01 está Ready"
    break
  fi

  if [[ "${attempt}" -eq 60 ]]; then
    systemctl status k3s --no-pager || true
    journalctl -u k3s --no-pager -n 100 || true
    fail "O nó não ficou Ready dentro do período de validação."
  fi

  sleep 5
done

log "Versão instalada"
k3s --version

log "Nós"
k3s kubectl get nodes -o wide

log "Pods do sistema"
k3s kubectl get pods -n kube-system -o wide

log "Criptografia de Secrets"
k3s secrets-encrypt status

log "Instalação concluída"
EOF
