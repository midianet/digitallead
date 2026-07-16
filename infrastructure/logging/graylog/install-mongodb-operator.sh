#!/usr/bin/env bash

set -Eeuo pipefail

RELEASE_NAME="${RELEASE_NAME:-mongodb-kubernetes}"
NAMESPACE="${NAMESPACE:-dl-logging}"
CHART_VERSION="${CHART_VERSION:-1.9.1}"

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

kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 ||
  fail "Namespace ${NAMESPACE} não encontrado."

log "Instalando MongoDB Kubernetes Operator ${CHART_VERSION}"

helm upgrade \
  --install \
  "${RELEASE_NAME}" \
  mongodb-kubernetes/mongodb-kubernetes \
  --namespace "${NAMESPACE}" \
  --version "${CHART_VERSION}" \
  --values "${SCRIPT_DIRECTORY}/mongodb-operator-values.yaml" \
  --atomic \
  --timeout 10m \
  --history-max 10

log "MongoDB Kubernetes Operator instalado"

helm status "${RELEASE_NAME}" \
  --namespace "${NAMESPACE}"
