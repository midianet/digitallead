#!/usr/bin/env bash

set -Eeuo pipefail

REPOSITORY_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." &&
  pwd
)"

SOURCE="${REPOSITORY_ROOT}/infrastructure/backup/postgresql/backup.sh"
TARGET="${REPOSITORY_ROOT}/infrastructure/backup/postgresql/configmap.yaml"

[[ -f "${SOURCE}" ]] || {
  echo "Arquivo não encontrado: ${SOURCE}" >&2
  exit 1
}

{
  cat <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgresql-backup-script
  namespace: dl-database
  labels:
    app.kubernetes.io/name: postgresql-backup
    app.kubernetes.io/part-of: digitallead-platform
data:
  backup.sh: |
EOF

  sed 's/^/    /' "${SOURCE}"
} > "${TARGET}"

echo "ConfigMap gerado em ${TARGET}"
