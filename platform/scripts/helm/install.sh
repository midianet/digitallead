#!/usr/bin/env bash

set -Eeuo pipefail

PLATFORM_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../../.."
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

  $0 kube-prometheus-stack
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
    fail "Campo obrigatório não encontrado: ${description}"

  printf '%s' "${value}"
}

read_optional_value() {
  local expression="$1"
  local default_value="$2"

  local value

  value="$(
    yq eval "${expression} // \"\"" "${COMPONENT_FILE}"
  )"

  if [[ -z "${value}" ]]; then
    value="${default_value}"
  fi

  printf '%s' "${value}"
}

[[ "$#" -eq 1 ]] || {
  usage
  exit 1
}

require_command helm
require_command kubectl
require_command yq

COMPONENT_NAME="$1"
COMPONENT_DIRECTORY="${COMPONENTS_ROOT}/${COMPONENT_NAME}"
COMPONENT_FILE="${COMPONENT_DIRECTORY}/component.yaml"

[[ -d "${COMPONENT_DIRECTORY}" ]] ||
  fail "Componente não encontrado: ${COMPONENT_NAME}"

[[ -f "${COMPONENT_FILE}" ]] ||
  fail "Arquivo component.yaml não encontrado: ${COMPONENT_FILE}"

RELEASE_NAME="$(
  read_required_value '.release.name' 'release.name'
)"

NAMESPACE="$(
  read_required_value '.release.namespace' 'release.namespace'
)"

CHART_REPOSITORY_NAME="$(
  read_required_value '.chart.repository.name' 'chart.repository.name'
)"

CHART_REPOSITORY_URL="$(
  read_required_value '.chart.repository.url' 'chart.repository.url'
)"

CHART_NAME="$(
  read_required_value '.chart.name' 'chart.name'
)"

CHART_VERSION="$(
  read_required_value '.chart.version' 'chart.version'
)"

VALUES_FILE_NAME="$(
  read_optional_value '.values.file' 'values.yaml'
)"

CREATE_NAMESPACE="$(
  read_optional_value '.release.createNamespace' 'true'
)"

ATOMIC="$(
  read_optional_value '.release.atomic' 'true'
)"

TIMEOUT="$(
  read_optional_value '.release.timeout' '15m'
)"

HISTORY_MAX="$(
  read_optional_value '.release.historyMax' '10'
)"

VALUES_FILE="${COMPONENT_DIRECTORY}/${VALUES_FILE_NAME}"

[[ -f "${VALUES_FILE}" ]] ||
  fail "Arquivo values não encontrado: ${VALUES_FILE}"

log "Componente: ${COMPONENT_NAME}"
log "Release: ${RELEASE_NAME}"
log "Namespace: ${NAMESPACE}"
log "Chart: ${CHART_REPOSITORY_NAME}/${CHART_NAME}"
log "Versão: ${CHART_VERSION}"

if ! helm repo list \
  --output yaml |
  yq eval \
    ".[] | select(.name == \"${CHART_REPOSITORY_NAME}\") | .name" - |
  grep -qx "${CHART_REPOSITORY_NAME}"; then

  log "Adicionando repositório Helm ${CHART_REPOSITORY_NAME}"

  helm repo add \
    "${CHART_REPOSITORY_NAME}" \
    "${CHART_REPOSITORY_URL}"
fi

log "Atualizando repositórios Helm"

helm repo update

HELM_ARGUMENTS=(
  upgrade
  --install
  "${RELEASE_NAME}"
  "${CHART_REPOSITORY_NAME}/${CHART_NAME}"
  --namespace
  "${NAMESPACE}"
  --version
  "${CHART_VERSION}"
  --values
  "${VALUES_FILE}"
  --timeout
  "${TIMEOUT}"
  --history-max
  "${HISTORY_MAX}"
)

if [[ "${CREATE_NAMESPACE}" == "true" ]]; then
  HELM_ARGUMENTS+=(--create-namespace)
fi

if [[ "${ATOMIC}" == "true" ]]; then
  HELM_ARGUMENTS+=(--atomic)
fi

log "Instalando componente"

helm "${HELM_ARGUMENTS[@]}"

log "Instalação concluída"

helm status \
  "${RELEASE_NAME}" \
  --namespace "${NAMESPACE}"
