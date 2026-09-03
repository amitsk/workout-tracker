#!/usr/bin/env bash
# Apply the minimal schema + seed and run smoke assertions.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"${ROOT}/scripts/apply-schema.sh" minimal --seed

if [[ -z "${DATABASE_URL:-}" ]]; then
  export PGHOST="${PGHOST:-localhost}"
  export PGPORT="${PGPORT:-5433}"
  export PGUSER="${PGUSER:-workout}"
  export PGPASSWORD="${PGPASSWORD:-workout}"
  export PGDATABASE="${PGDATABASE:-workout_tracker}"
  DATABASE_URL="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"
fi

psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 <<'SQL'
DO $$
DECLARE
  n_users INT;
  n_sets INT;
  n_null_weight INT;
  mixed INT;
BEGIN
  SELECT COUNT(*) INTO n_users FROM users;
  IF n_users <> 3 THEN
    RAISE EXCEPTION 'expected 3 users, got %', n_users;
  END IF;

  -- email trigger lowercases
  IF EXISTS (SELECT 1 FROM users WHERE email <> lower(email)) THEN
    RAISE EXCEPTION 'emails were not normalized';
  END IF;

  SELECT COUNT(*) INTO n_sets FROM workout_sets;
  IF n_sets < 60 THEN
    RAISE EXCEPTION 'expected seeded sets, got %', n_sets;
  END IF;

  SELECT COUNT(*) INTO n_null_weight FROM workout_sets WHERE weight IS NULL;
  IF n_null_weight < 1 THEN
    RAISE EXCEPTION 'expected bodyweight sets with NULL weight';
  END IF;

  -- per-set variance: John's first bench is not a flat 4x8
  SELECT COUNT(DISTINCT weight) INTO mixed
  FROM workout_sets WHERE workout_id = 1;
  IF mixed < 2 THEN
    RAISE EXCEPTION 'expected multiple weights on workout 1, got %', mixed;
  END IF;

  -- restrict: deleting a used type must fail
  BEGIN
    DELETE FROM workout_types WHERE name = 'Bench Press';
    RAISE EXCEPTION 'deleting in-use workout type should have failed';
  EXCEPTION
    WHEN foreign_key_violation THEN
      NULL; -- expected
  END;
END $$;

SELECT 'verify-schema: ok' AS status;
SQL
