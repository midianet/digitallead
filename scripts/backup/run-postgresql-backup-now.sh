#!/usr/bin/env bash

set -Eeuo pipefail

JOB_NAME="postgresql-backup-manual-$(date '+%Y%m%d%H%M%S')"

sudo k3s kubectl create job \
  --from=cronjob/postgresql-backup \
  "${JOB_NAME}" \
  --namespace dl-database

echo "Job criado: ${JOB_NAME}"

sudo k3s kubectl wait \
  --for=condition=Complete \
  "job/${JOB_NAME}" \
  --namespace dl-database \
  --timeout=30m

sudo k3s kubectl logs \
  "job/${JOB_NAME}" \
  --namespace dl-database
