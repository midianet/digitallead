#!/usr/bin/env bash

set -Eeuo pipefail

REPOSITORY_ROOT="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." &&
  pwd
)"

PYTHON="${REPOSITORY_ROOT}/.venv/bin/python"
VALIDATOR="${REPOSITORY_ROOT}/scripts/catalog/validate-platform-catalog.py"

if [[ ! -x "${PYTHON}" ]]; then
  echo "ERRO: ambiente virtual não encontrado em ${PYTHON}." >&2
  echo "Execute: python3 -m venv .venv" >&2
  echo "Depois: .venv/bin/pip install -r requirements-dev.txt" >&2
  exit 1
fi

exec "${PYTHON}" "${VALIDATOR}" "$@"
