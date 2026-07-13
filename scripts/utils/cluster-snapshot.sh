#!/usr/bin/env bash

set -Eeuo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT_DIR="${REPOSITORY_ROOT}/reports/cluster-snapshot/${TIMESTAMP}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

fail() {
  printf 'ERRO: %s\n' "$1" >&2
  exit 1
}

if [[ "${EUID}" -ne 0 ]]; then
  fail "Execute com sudo para garantir acesso ao kubeconfig do K3s."
fi

if ! command -v k3s >/dev/null 2>&1; then
  fail "O comando k3s não foi encontrado."
fi

if ! systemctl is-active --quiet k3s; then
  fail "O serviço k3s não está ativo."
fi

mkdir -p "${REPORT_DIR}"

log "Gerando fotografia do cluster em:"
log "${REPORT_DIR}"

{
  echo "Plataforma Digitalead"
  echo "Fotografia do cluster K3s"
  echo
  echo "Data local: $(date --iso-8601=seconds)"
  echo "Data UTC:   $(date --utc --iso-8601=seconds)"
  echo "Hostname:   $(hostname)"
  echo "Kernel:     $(uname -r)"
  echo "Sistema:    $(. /etc/os-release && echo "${PRETTY_NAME}")"
  echo "Timezone:   $(timedatectl show --property=Timezone --value)"
  echo "Git commit: $(git -C "${REPOSITORY_ROOT}" rev-parse HEAD 2>/dev/null || echo 'não disponível')"
} > "${REPORT_DIR}/metadata.txt"

k3s --version \
  > "${REPORT_DIR}/k3s-version.txt" 2>&1

k3s kubectl version \
  > "${REPORT_DIR}/kubernetes-version.txt" 2>&1

k3s kubectl cluster-info \
  > "${REPORT_DIR}/cluster-info.txt" 2>&1

k3s kubectl get nodes -o wide \
  > "${REPORT_DIR}/nodes.txt" 2>&1

k3s kubectl describe nodes \
  > "${REPORT_DIR}/nodes-describe.txt" 2>&1

k3s kubectl get namespaces \
  > "${REPORT_DIR}/namespaces.txt" 2>&1

k3s kubectl get pods --all-namespaces -o wide \
  > "${REPORT_DIR}/pods-all.txt" 2>&1

k3s kubectl get pods -n kube-system -o wide \
  > "${REPORT_DIR}/pods-kube-system.txt" 2>&1

k3s kubectl get deployments --all-namespaces -o wide \
  > "${REPORT_DIR}/deployments.txt" 2>&1

k3s kubectl get daemonsets --all-namespaces -o wide \
  > "${REPORT_DIR}/daemonsets.txt" 2>&1

k3s kubectl get statefulsets --all-namespaces -o wide \
  > "${REPORT_DIR}/statefulsets.txt" 2>&1

k3s kubectl get services --all-namespaces -o wide \
  > "${REPORT_DIR}/services.txt" 2>&1

k3s kubectl get ingresses --all-namespaces -o wide \
  > "${REPORT_DIR}/ingresses.txt" 2>&1

k3s kubectl get storageclasses -o wide \
  > "${REPORT_DIR}/storageclasses.txt" 2>&1

k3s kubectl get persistentvolumes -o wide \
  > "${REPORT_DIR}/persistent-volumes.txt" 2>&1

k3s kubectl get persistentvolumeclaims --all-namespaces -o wide \
  > "${REPORT_DIR}/persistent-volume-claims.txt" 2>&1

k3s kubectl get configmaps --all-namespaces \
  > "${REPORT_DIR}/configmaps.txt" 2>&1

k3s kubectl get customresourcedefinitions \
  > "${REPORT_DIR}/crds.txt" 2>&1

k3s kubectl api-resources \
  > "${REPORT_DIR}/api-resources.txt" 2>&1

k3s kubectl get events \
  --all-namespaces \
  --sort-by='.metadata.creationTimestamp' \
  > "${REPORT_DIR}/events.txt" 2>&1

k3s kubectl get all --all-namespaces -o wide \
  > "${REPORT_DIR}/all-resources.txt" 2>&1

df -hT \
  > "${REPORT_DIR}/disk-usage.txt" 2>&1

free -h \
  > "${REPORT_DIR}/memory-usage.txt" 2>&1

ss -lntup \
  > "${REPORT_DIR}/listening-ports.txt" 2>&1

systemctl status k3s --no-pager \
  > "${REPORT_DIR}/k3s-service-status.txt" 2>&1 || true

journalctl -u k3s --no-pager -n 300 \
  > "${REPORT_DIR}/k3s-journal.txt" 2>&1 || true

log "Fotografia concluída."

echo
echo "Arquivos gerados:"
find "${REPORT_DIR}" -maxdepth 1 -type f -printf '%f\n' | sort

echo
echo "Diretório:"
echo "${REPORT_DIR}"
