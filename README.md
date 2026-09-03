# Workout Tracker

Artifacts for a weight-training (and, in the larger variant, multi-activity) tracker: PostgreSQL schema, seeds, queries, OpenAPI, and requirements.

This repository is **schema and contract**, not a running application. A proposed CRUD web app is in [`docs/web-app-crud-design.md`](docs/web-app-crud-design.md).

## Two variants

| Directory | What it is | Use when |
|-----------|------------|----------|
| [`minimal-workouts/`](minimal-workouts/) | Five tables: users, workout types, sessions, exercise blocks, **per-set load** | Building the first product: log gym sessions |
| [`comprehensive-workouts/`](comprehensive-workouts/) | Activity hierarchy, EAV metrics, programs, social, goals, PRs | Long-term product vision; **do not start the web app here** |

Product-level requirements for the large vision: [`requirements/comprehensive.md`](requirements/comprehensive.md).

## Layout

```
minimal-workouts/
  requirements.md          MVP functional requirements (v1.1)
  database/schema.sql      Source of truth for the minimal model
  database/schema.md
  database/seed_data.sql
  database/queries/
  diagrams/er_diagram.mmd
  api/openapi.yaml
  api/requirements.md
  api/examples/
comprehensive-workouts/    Same shape, larger model
docs/web-app-crud-design.md
scripts/apply-schema.sh
scripts/verify-schema.sh
docker-compose.yml         PostgreSQL 16 on localhost:5433
```

The previous root README described a single `database/` / `api/` / `mobile/` tree and an `indexes.sql` file that never existed. Paths below are the ones that are actually in the repo.

## Prerequisites

- Docker (for the bundled Postgres)
- `psql` (PostgreSQL 14+ client)
- `make` (optional; the scripts work without it)

## Build the schema

Postgres is exposed on **5433** so it does not collide with a local 5432 instance.

```bash
# start the database
make db-up

# minimal schema + sample rows (the default path)
make seed-minimal

# assert seed counts, email normalization, and ON DELETE RESTRICT
make verify-minimal

# comprehensive variant (overwrites the same database)
make seed-comprehensive
```

Equivalent without Make:

```bash
docker compose up -d db
export DATABASE_URL=postgresql://workout:workout@localhost:5433/workout_tracker
./scripts/apply-schema.sh minimal --seed
./scripts/verify-schema.sh
```

`schema.sql` drops and recreates objects, so re-running `apply-schema.sh` is a reset of that variant’s tables.

Open a shell:

```bash
make db-psql
```

Connection:

```
postgresql://workout:workout@localhost:5433/workout_tracker
```

## Minimal model (v1.1)

```
users 1──N sessions 1──N workouts 1──N workout_sets
                              N──1 workout_types
```

- A **session** is a gym visit (`started_at` timestamptz).
- A **workout** is an exercise block in that session (Bench Press as movement #1).
- A **workout_set** is one set: reps, optional weight, `kg` or `lbs`.
- Bodyweight work uses `weight = NULL`.
- Deleting a workout type that has history is rejected.

## API

Contract: [`minimal-workouts/api/openapi.yaml`](minimal-workouts/api/openapi.yaml).

Public: `POST /users`, `POST /auth/login`. Everything else is Bearer JWT. Sessions, workouts, and sets are scoped to the authenticated user (`GET /users/me`, not a user directory).

## What this repo does not contain

- Application server or UI (see the web-app design doc)
- Migrations framework (the SQL files are full rebuilds, not incremental Alembic/Flyway)
- Production secrets (seed password hashes are placeholders)
