#!/usr/bin/env bash

set -Eeuo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION_FILE="${REPOSITORY_ROOT}/infrastructure/helm/version.env"

DOWNLOAD_DIR="$(mktemp -d)"
INSTALL_DIR="/usr/local/bin"
ARCHIVE_NAME=""
DOWNLOAD_URL=""

log() {
  printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

fail() {
  printf '\nERRO: %s\n' "$1" >&2
  exit 1
}

cleanup() {
  rm -rf "${DOWNLOAD_DIR}"
}

trap cleanup EXIT

if [[ "${EUID}" -ne 0 ]]; then
  fail "Execute este script com sudo."
fi

[[ -f "${VERSION_FILE}" ]] ||
  fail "Arquivo de versão não encontrado: ${VERSION_FILE}"

# shellcheck disable=SC1090
source "${VERSION_FILE}"

[[ -n "${HELM_VERSION:-}" ]] ||
  fail "HELM_VERSION não foi definida."

[[ -n "${HELM_SHA256:-}" ]] ||
  fail "HELM_SHA256 não foi definida."

ARCHIVE_NAME="helm-${HELM_VERSION}-linux-amd64.tar.gz"
DOWNLOAD_URL="https://get.helm.sh/${ARCHIVE_NAME}"

if command -v helm >/dev/null 2>&1; then
  CURRENT_VERSION="$(helm version --short 2>/dev/null || true)"

  if [[ "${CURRENT_VERSION}" == *"${HELM_VERSION}"* ]]; then
    log "Helm ${HELM_VERSION} já está instalado."
    helm version
    exit 0
  fi

  fail "Outra versão do Helm já está instalada: ${CURRENT_VERSION}"
fi

log "Baixando Helm ${HELM_VERSION}"
curl \
  --fail \
  --silent \
  --show-error \
  --location \
  "${DOWNLOAD_URL}" \
  --output "${DOWNLOAD_DIR}/${ARCHIVE_NAME}"

log "Validando checksum SHA-256"
printf '%s  %s\n' \
  "${HELM_SHA256}" \
  "${DOWNLOAD_DIR}/${ARCHIVE_NAME}" |
  sha256sum --check --status ||
  fail "O checksum do pacote não corresponde ao valor oficial."

log "Extraindo pacote"
tar \
  --extract \
  --gzip \
  --file "${DOWNLOAD_DIR}/${ARCHIVE_NAME}" \
  --directory "${DOWNLOAD_DIR}"

[[ -f "${DOWNLOAD_DIR}/linux-amd64/helm" ]] ||
  fail "Binário do Helm não encontrado após a extração."

log "Instalando em ${INSTALL_DIR}/helm"
install \
  -o root \
  -g root \
  -m 755 \
  "${DOWNLOAD_DIR}/linux-amd64/helm" \
  "${INSTALL_DIR}/helm"

log "Validando instalação"
helm version

log "Helm instalado com sucesso."
