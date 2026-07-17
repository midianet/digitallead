#!/usr/bin/env bash

set -Eeuo pipefail

PLATFORM_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.."
  pwd
)"

COMPONENTS_ROOT="${PLATFORM_ROOT}/platform/components"

DEFAULT_TIMEOUT="20m"
DEFAULT_HISTORY_MAX="10"

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

Exemplos:

  $0 graylog
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
    fail "Campo obrigatório ausente: ${description}"

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
  fail "Arquivo não encontrado: ${COMPONENT_FILE}"

COMPONENT_KIND="$(
  read_required_value '.kind' 'kind'
)"

[[ "${COMPONENT_KIND}" == "HelmComponent" ]] ||
  fail "Tipo de componente não suportado: ${COMPONENT_KIND}"

RELEASE_NAME="$(
  read_required_value '.release.name' 'release.name'
)"

NAMESPACE="$(
  read_required_value '.release.namespace' 'release.namespace'
)"

REPOSITORY_NAME="$(
  read_required_value '.chart.repository.name' 'chart.repository.name'
)"

REPOSITORY_URL="$(
  read_required_value '.chart.repository.url' 'chart.repository.url'
)"

CHART_NAME="$(
  read_required_value '.chart.name' 'chart.name'
)"

CHART_VERSION="$(
  read_required_value '.chart.version' 'chart.version'
)"

VALUES_FILE_NAME="$(
  yq eval '.values.file // "values.yaml"' "${COMPONENT_FILE}"
)"

VALUES_FILE="${COMPONENT_DIRECTORY}/${VALUES_FILE_NAME}"

[[ -f "${VALUES_FILE}" ]] ||
  fail "Arquivo values não encontrado: ${VALUES_FILE}"

log "Componente: ${COMPONENT_NAME}"
log "Release: ${RELEASE_NAME}"
log "Namespace: ${NAMESPACE}"
log "Chart: ${REPOSITORY_NAME}/${CHART_NAME}"
log "Versão: ${CHART_VERSION}"
log "Values: ${VALUES_FILE}"

log "Registrando repositório Helm"

helm repo add \
  "${REPOSITORY_NAME}" \
  "${REPOSITORY_URL}" \
  --force-update >/dev/null

log "Atualizando repositórios Helm"

helm repo update >/dev/null

log "Executando helm upgrade --install"

helm upgrade \
  --install \
  "${RELEASE_NAME}" \
  "${REPOSITORY_NAME}/${CHART_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --version "${CHART_VERSION}" \
  --values "${VALUES_FILE}" \
  --atomic \
  --timeout "${DEFAULT_TIMEOUT}" \
  --history-max "${DEFAULT_HISTORY_MAX}"

log "Instalação concluída"

helm status \
  "${RELEASE_NAME}" \
  --namespace "${NAMESPACE}"
