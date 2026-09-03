COMPOSE ?= docker compose
DB_URL  ?= postgresql://workout:workout@localhost:5433/workout_tracker
export DATABASE_URL = $(DB_URL)

.PHONY: help db-up db-down db-wait db-psql \
	schema-minimal seed-minimal verify-minimal reset-minimal \
	schema-comprehensive seed-comprehensive reset-comprehensive

help:
	@echo "Targets:"
	@echo "  make db-up                 Start PostgreSQL 16 on localhost:5433"
	@echo "  make db-down               Stop the database container (keeps volume)"
	@echo "  make seed-minimal          Apply minimal schema + sample rows"
	@echo "  make verify-minimal        Schema + seed + smoke assertions"
	@echo "  make reset-minimal         Recreate volume, then seed-minimal"
	@echo "  make seed-comprehensive    Apply comprehensive schema + sample rows"
	@echo "  make db-psql               Open psql against the compose database"

db-up:
	$(COMPOSE) up -d db
	$(MAKE) db-wait

db-down:
	$(COMPOSE) down

db-wait:
	@echo "Waiting for Postgres..."
	@i=0; \
	until $(COMPOSE) exec -T db pg_isready -U workout -d workout_tracker >/dev/null 2>&1; do \
	  i=$$((i+1)); \
	  if [ $$i -gt 30 ]; then echo "Postgres did not become ready" >&2; exit 1; fi; \
	  sleep 1; \
	done
	@echo "Postgres is ready on localhost:5433"

db-psql:
	$(COMPOSE) exec db psql -U workout -d workout_tracker

schema-minimal: db-up
	./scripts/apply-schema.sh minimal

seed-minimal: db-up
	./scripts/apply-schema.sh minimal --seed

verify-minimal: db-up
	./scripts/verify-schema.sh

reset-minimal:
	$(COMPOSE) down -v
	$(MAKE) seed-minimal

schema-comprehensive: db-up
	./scripts/apply-schema.sh comprehensive

seed-comprehensive: db-up
	./scripts/apply-schema.sh comprehensive --seed

reset-comprehensive:
	$(COMPOSE) down -v
	$(MAKE) seed-comprehensive
