#!/usr/bin/env bash

set -Eeuo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/backup/postgresql}"
POSTGRES_HOST="${POSTGRES_HOST:-postgresql.dl-database.svc.cluster.local}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
YEAR="$(date '+%Y')"
MONTH="$(date '+%m')"
DAY="$(date '+%d')"

BACKUP_DIR="${BACKUP_ROOT}/${YEAR}/${MONTH}/${DAY}"
GLOBALS_FILE="${BACKUP_DIR}/globals-${TIMESTAMP}.sql.gz"
DATABASES_DIR="${BACKUP_DIR}/databases"
METADATA_FILE="${BACKUP_DIR}/metadata-${TIMESTAMP}.txt"
CHECKSUM_FILE="${BACKUP_DIR}/sha256-${TIMESTAMP}.txt"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

fail() {
  printf 'ERRO: %s\n' "$1" >&2
  exit 1
}

[[ -n "${PGPASSWORD:-}" ]] ||
  fail "A variável PGPASSWORD não foi definida."

mkdir -p "${DATABASES_DIR}"

START_EPOCH="$(date +%s)"

log "Validando conexão com PostgreSQL"

pg_isready \
  --host="${POSTGRES_HOST}" \
  --port="${POSTGRES_PORT}" \
  --username="${POSTGRES_USER}"

log "Obtendo lista de bancos"

mapfile -t DATABASES < <(
  psql \
    --host="${POSTGRES_HOST}" \
    --port="${POSTGRES_PORT}" \
    --username="${POSTGRES_USER}" \
    --dbname=postgres \
    --tuples-only \
    --no-align \
    --command="
      SELECT datname
      FROM pg_database
      WHERE datallowconn = true
        AND datistemplate = false
      ORDER BY datname;
    "
)

if [[ "${#DATABASES[@]}" -eq 0 ]]; then
  fail "Nenhum banco foi encontrado."
fi

log "Gerando backup de roles e objetos globais"

pg_dumpall \
  --host="${POSTGRES_HOST}" \
  --port="${POSTGRES_PORT}" \
  --username="${POSTGRES_USER}" \
  --globals-only |
gzip -9 > "${GLOBALS_FILE}"

for database in "${DATABASES[@]}"; do
  backup_file="${DATABASES_DIR}/${database}-${TIMESTAMP}.dump"

  log "Gerando backup do banco ${database}"

  pg_dump \
    --host="${POSTGRES_HOST}" \
    --port="${POSTGRES_PORT}" \
    --username="${POSTGRES_USER}" \
    --dbname="${database}" \
    --format=custom \
    --compress=9 \
    --no-owner \
    --file="${backup_file}"
done

END_EPOCH="$(date +%s)"
DURATION_SECONDS="$((END_EPOCH - START_EPOCH))"

POSTGRES_VERSION="$(
  psql \
    --host="${POSTGRES_HOST}" \
    --port="${POSTGRES_PORT}" \
    --username="${POSTGRES_USER}" \
    --dbname=postgres \
    --tuples-only \
    --no-align \
    --command='SHOW server_version;'
)"

{
  echo "platform=digitallead"
  echo "cluster=digitallead"
  echo "namespace=dl-database"
  echo "service=postgresql"
  echo "timestamp=${TIMESTAMP}"
  echo "postgres_version=${POSTGRES_VERSION}"
  echo "database_count=${#DATABASES[@]}"
  echo "duration_seconds=${DURATION_SECONDS}"
  echo "backup_directory=${BACKUP_DIR}"
} > "${METADATA_FILE}"

log "Gerando checksums"

find "${BACKUP_DIR}" \
  -type f \
  ! -name "$(basename "${CHECKSUM_FILE}")" \
  -print0 |
sort -z |
xargs -0 sha256sum > "${CHECKSUM_FILE}"

log "Removendo backups com mais de ${RETENTION_DAYS} dias"

find "${BACKUP_ROOT}" \
  -mindepth 3 \
  -maxdepth 3 \
  -type d \
  -mtime "+${RETENTION_DAYS}" \
  -print \
  -exec rm -rf -- {} +

log "Backup concluído em ${DURATION_SECONDS} segundos"

du -sh "${BACKUP_DIR}"
