#!/usr/bin/env bash

set -Eeuo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-/backup/postgresql}"

POSTGRES_HOST="${POSTGRES_HOST:-postgresql.dl-database.svc.cluster.local}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"

BACKUP_TIMESTAMP="${BACKUP_TIMESTAMP:-}"
DATABASE_FILTER="${DATABASE_FILTER:-}"

RESTORE_PREFIX="${RESTORE_PREFIX:-dl_restore_validation}"
KEEP_TEMP_DATABASE="${KEEP_TEMP_DATABASE:-false}"

declare -a TEMP_DATABASES=()

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

fail() {
  printf '[%s] ERRO: %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$1" >&2

  exit 1
}

sanitize_database_name() {
  local name="$1"

  name="$(
    printf '%s' "${name}" |
      tr '[:upper:]' '[:lower:]' |
      sed 's/[^a-z0-9_]/_/g' |
      sed 's/__*/_/g' |
      sed 's/^_*//' |
      sed 's/_*$//'
  )"

  printf '%.30s' "${name}"
}

database_exists() {
  local database="$1"

  psql \
    --host="${POSTGRES_HOST}" \
    --port="${POSTGRES_PORT}" \
    --username="${POSTGRES_USER}" \
    --dbname=postgres \
    --tuples-only \
    --no-align \
    --command="
      SELECT 1
      FROM pg_database
      WHERE datname = '${database}';
    " |
    grep -q '^1$'
}

drop_database() {
  local database="$1"

  log "Removendo banco temporário ${database}"

  psql \
    --host="${POSTGRES_HOST}" \
    --port="${POSTGRES_PORT}" \
    --username="${POSTGRES_USER}" \
    --dbname=postgres \
    --set=ON_ERROR_STOP=1 \
    --command="
      SELECT pg_terminate_backend(pid)
      FROM pg_stat_activity
      WHERE datname = '${database}'
        AND pid <> pg_backend_pid();
    " >/dev/null

  dropdb \
    --host="${POSTGRES_HOST}" \
    --port="${POSTGRES_PORT}" \
    --username="${POSTGRES_USER}" \
    --if-exists \
    "${database}"
}

cleanup() {
  local exit_code=$?

  if [[ "${KEEP_TEMP_DATABASE}" == "true" ]]; then
    log "KEEP_TEMP_DATABASE=true; bancos temporários serão preservados."
    exit "${exit_code}"
  fi

  for database in "${TEMP_DATABASES[@]:-}"; do
    drop_database "${database}" || true
  done

  exit "${exit_code}"
}

trap cleanup EXIT
trap 'fail "Falha na linha ${LINENO}: ${BASH_COMMAND}"' ERR

[[ -n "${PGPASSWORD:-}" ]] ||
  fail "A variável PGPASSWORD não foi definida."

[[ -d "${BACKUP_ROOT}" ]] ||
  fail "Diretório de backup não encontrado: ${BACKUP_ROOT}"

log "Validando conexão com PostgreSQL"

pg_isready \
  --host="${POSTGRES_HOST}" \
  --port="${POSTGRES_PORT}" \
  --username="${POSTGRES_USER}"

if [[ -n "${BACKUP_TIMESTAMP}" ]]; then
  CHECKSUM_FILE="$(
    find "${BACKUP_ROOT}" \
      -type f \
      -name "sha256-${BACKUP_TIMESTAMP}.txt" \
      -print \
      -quit
  )"
else
  CHECKSUM_FILE="$(
    find "${BACKUP_ROOT}" \
      -type f \
      -name 'sha256-*.txt' \
      -printf '%T@ %p\n' |
    sort -nr |
    head -n 1 |
    cut -d' ' -f2-
  )"
fi

[[ -n "${CHECKSUM_FILE}" ]] ||
  fail "Nenhum arquivo de checksum foi encontrado."

BACKUP_DIRECTORY="$(dirname "${CHECKSUM_FILE}")"

CHECKSUM_FILENAME="$(basename "${CHECKSUM_FILE}")"

SELECTED_TIMESTAMP="$(
  printf '%s' "${CHECKSUM_FILENAME}" |
    sed -E 's/^sha256-(.*)\.txt$/\1/'
)"

DATABASES_DIRECTORY="${BACKUP_DIRECTORY}/databases"
GLOBALS_FILE="${BACKUP_DIRECTORY}/globals-${SELECTED_TIMESTAMP}.sql.gz"
METADATA_FILE="${BACKUP_DIRECTORY}/metadata-${SELECTED_TIMESTAMP}.txt"

log "Backup selecionado"
log "Diretório: ${BACKUP_DIRECTORY}"
log "Timestamp: ${SELECTED_TIMESTAMP}"

[[ -d "${DATABASES_DIRECTORY}" ]] ||
  fail "Diretório de bancos não encontrado: ${DATABASES_DIRECTORY}"

[[ -f "${GLOBALS_FILE}" ]] ||
  fail "Arquivo de objetos globais não encontrado: ${GLOBALS_FILE}"

[[ -f "${METADATA_FILE}" ]] ||
  fail "Arquivo de metadados não encontrado: ${METADATA_FILE}"

log "Metadados do backup"

sed 's/^/  /' "${METADATA_FILE}"

log "Validando checksums"

(
  cd /
  sha256sum --check "${CHECKSUM_FILE}"
)

log "Validando arquivo de objetos globais"

gzip --test "${GLOBALS_FILE}"

mapfile -t DUMP_FILES < <(
  find "${DATABASES_DIRECTORY}" \
    -maxdepth 1 \
    -type f \
    -name "*-${SELECTED_TIMESTAMP}.dump" \
    -print |
  sort
)

[[ "${#DUMP_FILES[@]}" -gt 0 ]] ||
  fail "Nenhum dump foi encontrado para ${SELECTED_TIMESTAMP}."

RESTORED_DATABASE_COUNT=0
TOTAL_TABLE_COUNT=0
TOTAL_OBJECT_COUNT=0

for dump_file in "${DUMP_FILES[@]}"; do
  dump_filename="$(basename "${dump_file}")"

  source_database="$(
    printf '%s' "${dump_filename}" |
      sed "s/-${SELECTED_TIMESTAMP}\.dump$//"
  )"

  if [[ -n "${DATABASE_FILTER}" ]] &&
     [[ "${source_database}" != "${DATABASE_FILTER}" ]]; then
    log "Ignorando banco ${source_database}; filtro=${DATABASE_FILTER}"
    continue
  fi

  safe_database_name="$(sanitize_database_name "${source_database}")"

  timestamp_suffix="$(
    printf '%s' "${SELECTED_TIMESTAMP}" |
      tr -d '-' |
      tail -c 13
  )"

  temp_database="${RESTORE_PREFIX}_${safe_database_name}_${timestamp_suffix}"
  temp_database="$(printf '%.63s' "${temp_database}")"

  log "Validando estrutura do dump ${dump_filename}"

  object_count="$(
    pg_restore --list "${dump_file}" |
      grep -Ev '^(;|$)' |
      wc -l |
      tr -d ' '
  )"

  [[ "${object_count}" -gt 0 ]] ||
    fail "O dump ${dump_filename} não contém objetos restauráveis."

  if database_exists "${temp_database}"; then
    log "Banco temporário já existe e será recriado: ${temp_database}"
    drop_database "${temp_database}"
  fi

  log "Criando banco temporário ${temp_database}"

  createdb \
    --host="${POSTGRES_HOST}" \
    --port="${POSTGRES_PORT}" \
    --username="${POSTGRES_USER}" \
    --template=template0 \
    "${temp_database}"

  TEMP_DATABASES+=("${temp_database}")

  log "Restaurando ${source_database} em ${temp_database}"

  pg_restore \
    --host="${POSTGRES_HOST}" \
    --port="${POSTGRES_PORT}" \
    --username="${POSTGRES_USER}" \
    --dbname="${temp_database}" \
    --no-owner \
    --no-privileges \
    --exit-on-error \
    --single-transaction \
    "${dump_file}"

  log "Executando validações no banco ${temp_database}"

  psql \
    --host="${POSTGRES_HOST}" \
    --port="${POSTGRES_PORT}" \
    --username="${POSTGRES_USER}" \
    --dbname="${temp_database}" \
    --set=ON_ERROR_STOP=1 \
    --command='SELECT 1;' >/dev/null

  table_count="$(
    psql \
      --host="${POSTGRES_HOST}" \
      --port="${POSTGRES_PORT}" \
      --username="${POSTGRES_USER}" \
      --dbname="${temp_database}" \
      --tuples-only \
      --no-align \
      --set=ON_ERROR_STOP=1 \
      --command="
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema NOT IN (
          'pg_catalog',
          'information_schema'
        )
        AND table_type = 'BASE TABLE';
      "
  )"

  schema_count="$(
    psql \
      --host="${POSTGRES_HOST}" \
      --port="${POSTGRES_PORT}" \
      --username="${POSTGRES_USER}" \
      --dbname="${temp_database}" \
      --tuples-only \
      --no-align \
      --set=ON_ERROR_STOP=1 \
      --command="
        SELECT COUNT(*)
        FROM information_schema.schemata
        WHERE schema_name NOT IN (
          'pg_catalog',
          'information_schema',
          'pg_toast'
        );
      "
  )"

  database_size="$(
    psql \
      --host="${POSTGRES_HOST}" \
      --port="${POSTGRES_PORT}" \
      --username="${POSTGRES_USER}" \
      --dbname="${temp_database}" \
      --tuples-only \
      --no-align \
      --set=ON_ERROR_STOP=1 \
      --command="
        SELECT pg_size_pretty(
          pg_database_size(current_database())
        );
      "
  )"

  log "Restore validado com sucesso"
  log "Banco original: ${source_database}"
  log "Banco temporário: ${temp_database}"
  log "Objetos no dump: ${object_count}"
  log "Schemas restaurados: ${schema_count}"
  log "Tabelas restauradas: ${table_count}"
  log "Tamanho restaurado: ${database_size}"

  RESTORED_DATABASE_COUNT="$((RESTORED_DATABASE_COUNT + 1))"
  TOTAL_TABLE_COUNT="$((TOTAL_TABLE_COUNT + table_count))"
  TOTAL_OBJECT_COUNT="$((TOTAL_OBJECT_COUNT + object_count))"

  if [[ "${KEEP_TEMP_DATABASE}" != "true" ]]; then
    drop_database "${temp_database}"

    TEMP_DATABASES=(
      "${TEMP_DATABASES[@]/${temp_database}}"
    )
  fi
done

[[ "${RESTORED_DATABASE_COUNT}" -gt 0 ]] ||
  fail "Nenhum banco foi restaurado. Verifique DATABASE_FILTER."

log "Validação de restore concluída com sucesso"
log "Backup validado: ${SELECTED_TIMESTAMP}"
log "Bancos restaurados: ${RESTORED_DATABASE_COUNT}"
log "Objetos processados: ${TOTAL_OBJECT_COUNT}"
log "Tabelas restauradas: ${TOTAL_TABLE_COUNT}"
