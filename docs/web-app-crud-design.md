# CRUD web app for the minimal schema

**Status**: proposal (not implemented)  
**Date**: 2026-08-30  
**Target schema**: `minimal-workouts/` v1.1

This is a design for a web application that is a CRUD interface to the **minimal** PostgreSQL schema. It is not a design for `comprehensive-workouts/` (programs, social, EAV, PRs as tables). Ship the small logger first.

## Goal

A person can register, log in, pick a date/time, add exercises from the catalog, enter sets (reps + weight), and later edit or delete that history. The UI is the primary client of the OpenAPI contract in `minimal-workouts/api/openapi.yaml`.

## Non-goals (first release)

- Native mobile apps, offline sync
- Charts, 1RM, periodization
- Social feed, programs, body metrics
- Admin console for other people's data
- Implementing the comprehensive schema

## Approaches

### A. Next.js (App Router) + Drizzle + Auth.js + shadcn/ui — recommended

One TypeScript codebase. Drizzle maps 1:1 onto the existing SQL (`drizzle-kit pull` from the live database, or checked-in `schema.ts` that matches `schema.sql`). Server Components render lists; Server Actions (or Route Handlers that implement the OpenAPI) mutate. Auth.js (credentials provider) issues the same JWT the API spec describes, or a session cookie if the UI is the only client.

**Why this one**: the first client is a web CRUD app; a single deployable matches the size of the schema; types flow from tables to forms.

**Cost**: if a separate mobile client appears soon, Route Handlers must stay honest to OpenAPI rather than becoming UI-only server actions.

### B. FastAPI + SQLModel + Vite React — best if the API is the product

Python service implements `openapi.yaml` (or generates OpenAPI from SQLModel and we retire the hand-written file). React talks to `/v1`. Two processes, two languages.

**Why not first**: extra moving parts for five tables. Choose this if a native app is the *next* milestone, not a hypothetical.

### C. Django + HTMX — fastest admin-shaped CRUD

Django ORM or `inspectdb`, session auth, server-rendered forms. Poor fit for the existing JWT/OpenAPI contract and for a “log a workout” UX that wants an editable set grid.

## Recommendation

**Approach A**, with Route Handlers that *are* the v1 API so a future mobile client can reuse them:

```
Browser  →  Next.js (App Router + shadcn)
                │
                ├─ Route Handlers  /v1/*   (OpenAPI)
                ├─ Drizzle
                └─ PostgreSQL 16   (this repo's schema)
```

Auth: Auth.js credentials provider, bcrypt hashes in `users.password_hash`, JWT in `Authorization` for `/v1`, httpOnly cookie for the HTML app. Same `user_id` either way.

UI kit: Tailwind + shadcn/ui. No chart library in v1.

## Screens

| Route | Role |
|-------|------|
| `/login`, `/register` | Public |
| `/sessions` | Paginated list of *my* sessions, newest first |
| `/sessions/new` | **Primary UI**: datetime, notes, add-exercise, set grid, save (one `POST /sessions` with nested workouts) |
| `/sessions/[id]` | View + edit the same structure; delete session |
| `/workout-types` | Catalog list; add/rename; delete disabled when in use (409) |
| `/account` | `GET/PUT/DELETE /users/me` |

The new-session page is a nested form, not four separate CRUD pages. Flat CRUD for `workout_sets` exists in the API for edits (“change set 3 to 5 reps”) and is used from the session detail page, not as a standalone “Sets admin”.

Empty states: no sessions yet → CTA to `/sessions/new`. Catalog ships with seed types in development; production starts with the same eight types as `seed_data.sql` or an empty catalog plus “add type”.

## Domain mapping

| UI concept | Table |
|------------|-------|
| Account | `users` |
| Exercise name in the picker | `workout_types` |
| One gym visit | `sessions` |
| Row of an exercise in the log | `workouts` |
| One line in the set grid | `workout_sets` |

Validation lives in both places: HTML/Zod on the client for instant feedback; CHECK constraints and API 400s as the source of truth (`reps > 0`, `weight_unit IN ('kg','lbs')`, unique `(workout_id, set_number)`).

## Data flow (log a session)

1. Load `GET /workout-types` for the picker.
2. User builds a tree in client state: `{ started_at, notes, workouts: [{ workout_type_id, sets: [...] }] }`.
3. Submit `POST /sessions` (nested). On 201, navigate to `/sessions/{id}`.
4. Edit a single set: `PUT /workout-sets/{id}`.
5. Lists: `GET /sessions?limit=20&offset=0`; open: `GET /sessions/{id}` (nested).

Errors: the API error envelope `{ error: { code, message, details } }` maps to a form-level or field-level message. 401 → login. 403/404 on someone else's id → generic not found.

## Authorization

Every session/workout/set query includes `user_id` from the JWT (join through `sessions`). Never trust a body `user_id`. Workout types are global.

## Testing

- Schema: `make verify-minimal` (already in this repo).
- API: contract tests against OpenAPI (e.g. schemathesis or a small pytest/Playwright collection).
- UI: Playwright for register → log nested session → edit set → delete.

## Incremental PRs if this is built later

1. Docker DB + Drizzle schema pulled from `schema.sql` + Auth.js register/login.
2. Workout type catalog pages.
3. Session list + nested create (the product).
4. Session detail edit/delete + set-level PUT/DELETE.
5. Account page and hard-delete user.

## Key decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Schema | minimal v1.1, not comprehensive | Five tables vs ~30; matches the first user story |
| Stack | Next.js + Drizzle + Postgres | One language, SQL stays source of truth |
| API | Keep OpenAPI; implement it in Route Handlers | UI and a future second client share one contract |
| Nested POST | Yes for session create | One save for a whole workout, one transaction |
| Auth | JWT + cookie | Spec already says JWT; cookies are better for the browser |
| Charts | No | YAGNI until logging is used |

## Open questions (for whoever implements)

1. Cookie session only vs also issuing the JWT to the browser for `/v1` from the same origin.
2. Whether production exercise catalog is seeded or user-built.
3. Default weight unit: user preference column (not in schema today) vs last-used unit in the form.
