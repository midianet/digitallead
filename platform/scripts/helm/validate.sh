#!/usr/bin/env bash

set -Eeuo pipefail

PLATFORM_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../../.."
  pwd
)"

COMPONENTS_ROOT="${PLATFORM_ROOT}/platform/components"

fail() {
  printf 'ERRO: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 ||
    fail "Comando obrigatório não encontrado: $1"
}

[[ "$#" -eq 1 ]] ||
  fail "Uso: $0 <componente>"

require_command helm
require_command yq

COMPONENT_NAME="$1"
COMPONENT_DIRECTORY="${COMPONENTS_ROOT}/${COMPONENT_NAME}"
COMPONENT_FILE="${COMPONENT_DIRECTORY}/component.yaml"

[[ -f "${COMPONENT_FILE}" ]] ||
  fail "Arquivo não encontrado: ${COMPONENT_FILE}"

RELEASE_NAME="$(
  yq eval '.release.name' "${COMPONENT_FILE}"
)"

NAMESPACE="$(
  yq eval '.release.namespace' "${COMPONENT_FILE}"
)"

REPOSITORY_NAME="$(
  yq eval '.chart.repository.name' "${COMPONENT_FILE}"
)"

REPOSITORY_URL="$(
  yq eval '.chart.repository.url' "${COMPONENT_FILE}"
)"

CHART_NAME="$(
  yq eval '.chart.name' "${COMPONENT_FILE}"
)"

CHART_VERSION="$(
  yq eval '.chart.version' "${COMPONENT_FILE}"
)"

VALUES_FILE_NAME="$(
  yq eval '.values.file // "values.yaml"' "${COMPONENT_FILE}"
)"

VALUES_FILE="${COMPONENT_DIRECTORY}/${VALUES_FILE_NAME}"

helm repo add \
  "${REPOSITORY_NAME}" \
  "${REPOSITORY_URL}" \
  --force-update >/dev/null

helm repo update >/dev/null

helm template \
  "${RELEASE_NAME}" \
  "${REPOSITORY_NAME}/${CHART_NAME}" \
  --namespace "${NAMESPACE}" \
  --version "${CHART_VERSION}" \
  --values "${VALUES_FILE}" \
  >/tmp/"${COMPONENT_NAME}"-rendered.yaml

echo "Renderização concluída:"
echo "/tmp/${COMPONENT_NAME}-rendered.yaml"

wc -l "/tmp/${COMPONENT_NAME}-rendered.yaml"
