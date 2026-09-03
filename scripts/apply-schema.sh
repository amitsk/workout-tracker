#!/usr/bin/env bash
# Apply a schema variant to PostgreSQL.
#
# Usage:
#   ./scripts/apply-schema.sh minimal [--seed]
#   ./scripts/apply-schema.sh comprehensive [--seed]
#
# Connection (first match wins):
#   DATABASE_URL
#   PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE
#   default: postgresql://workout:workout@localhost:5433/workout_tracker
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VARIANT="${1:-}"
SEED="${2:-}"

usage() {
  echo "Usage: $0 {minimal|comprehensive} [--seed]" >&2
  exit 1
}

case "${VARIANT}" in
  minimal) DIR="${ROOT}/minimal-workouts/database" ;;
  comprehensive) DIR="${ROOT}/comprehensive-workouts/database" ;;
  *) usage ;;
esac

if [[ -n "${SEED}" && "${SEED}" != "--seed" ]]; then
  usage
fi

if [[ ! -f "${DIR}/schema.sql" ]]; then
  echo "schema.sql not found in ${DIR}" >&2
  exit 1
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  export PGHOST="${PGHOST:-localhost}"
  export PGPORT="${PGPORT:-5433}"
  export PGUSER="${PGUSER:-workout}"
  export PGPASSWORD="${PGPASSWORD:-workout}"
  export PGDATABASE="${PGDATABASE:-workout_tracker}"
  DATABASE_URL="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
fi

PSQL=(psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -q)

echo "Applying ${VARIANT} schema to ${DATABASE_URL%%:*}://***"
"${PSQL[@]}" -f "${DIR}/schema.sql"

if [[ "${SEED}" == "--seed" ]]; then
  if [[ ! -f "${DIR}/seed_data.sql" ]]; then
    echo "seed_data.sql not found in ${DIR}" >&2
    exit 1
  fi
  echo "Seeding ${VARIANT}"
  "${PSQL[@]}" -f "${DIR}/seed_data.sql"
fi

echo "Done."
