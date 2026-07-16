#!/usr/bin/env bash

set -Eeuo pipefail

RELEASE_NAME="${RELEASE_NAME:-kube-prometheus-stack}"
NAMESPACE="${NAMESPACE:-dl-monitoring}"
CHART_VERSION="${CHART_VERSION:-87.16.1}"

SCRIPT_DIRECTORY="$(
  cd "$(dirname "${BASH_SOURCE[0]}")"
  pwd
)"

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

command -v helm >/dev/null 2>&1 ||
  fail "Helm não encontrado."

command -v kubectl >/dev/null 2>&1 ||
  fail "kubectl não encontrado."

kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 ||
  fail "Namespace ${NAMESPACE} não encontrado."

kubectl get secret grafana-admin-credentials \
  --namespace "${NAMESPACE}" >/dev/null 2>&1 ||
  fail "Secret grafana-admin-credentials não encontrado."

log "Atualizando repositórios Helm"

helm repo update

log "Instalando ${RELEASE_NAME}, chart ${CHART_VERSION}"

helm upgrade \
  --install \
  "${RELEASE_NAME}" \
  prometheus-community/kube-prometheus-stack \
  --namespace "${NAMESPACE}" \
  --version "${CHART_VERSION}" \
  --values "${SCRIPT_DIRECTORY}/values.yaml" \
  --atomic \
  --timeout 15m \
  --history-max 10

log "Instalação concluída"

helm status "${RELEASE_NAME}" \
  --namespace "${NAMESPACE}"
