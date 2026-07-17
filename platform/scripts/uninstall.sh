#!/usr/bin/env bash

set -Eeuo pipefail

PLATFORM_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.."
  pwd
)"

COMPONENTS_ROOT="${PLATFORM_ROOT}/platform/components"

log() {
  printf '[%s] %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$1"
}

fail() {
  printf '[%s] ERRO: %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$1" >&2

  exit 1
}

usage() {
  cat <<EOF
Uso:

  $0 <componente>

Exemplo:

  $0 graylog

Observação:

  O comando remove a release Helm, mas não remove
  automaticamente PVCs, CRDs ou o namespace.
EOF
}

require_command() {
  local command_name="$1"

  command -v "${command_name}" >/dev/null 2>&1 ||
    fail "Comando obrigatório não encontrado: ${command_name}"
}

read_required_value() {
  local expression="$1"
  local description="$2"
  local value

  value="$(
    yq eval "${expression} // \"\"" "${COMPONENT_FILE}"
  )"

  [[ -n "${value}" ]] ||
    fail "Campo obrigatório ausente: ${description}"

  printf '%s' "${value}"
}

[[ "$#" -eq 1 ]] || {
  usage
  exit 1
}

require_command helm
require_command yq

COMPONENT_NAME="$1"
COMPONENT_DIRECTORY="${COMPONENTS_ROOT}/${COMPONENT_NAME}"
COMPONENT_FILE="${COMPONENT_DIRECTORY}/component.yaml"

[[ -f "${COMPONENT_FILE}" ]] ||
  fail "Arquivo não encontrado: ${COMPONENT_FILE}"

RELEASE_NAME="$(
  read_required_value '.release.name' 'release.name'
)"

NAMESPACE="$(
  read_required_value '.release.namespace' 'release.namespace'
)"

if ! helm status \
  "${RELEASE_NAME}" \
  --namespace "${NAMESPACE}" >/dev/null 2>&1; then

  log "Release ${RELEASE_NAME} não está instalada no namespace ${NAMESPACE}."
  exit 0
fi

log "Removendo release ${RELEASE_NAME}"

helm uninstall \
  "${RELEASE_NAME}" \
  --namespace "${NAMESPACE}" \
  --wait \
  --timeout 10m

log "Release removida"

log "PVCs, CRDs e namespace não foram removidos automaticamente."
