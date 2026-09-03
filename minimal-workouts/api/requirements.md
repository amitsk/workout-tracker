# Weight Training Workout Tracker — API Requirements

**Document version**: 1.2  
**Last updated**: 2026-09-02  
**Status**: REST API contract for the rapid MVP web logger (< 1 week build)

## 1. Purpose

REST API for the minimal Weight Training Workout Tracker. CRUD for:

- Users (register, profile)
- Workout types (system catalog + user custom exercises)
- Sessions (with optional `ended_at` for workout duration)
- Workouts (exercise blocks inside a session)
- Workout sets (load, reps, warmup flag)

## 2. Scope

| In scope | Out of scope |
|----------|-------------|
| CRUD for the five tables | Analytics products, PRs as first-class resources |
| JWT login & HttpOnly cookie support | OAuth / social login / MFA |
| Atomic session create & update (nested payloads) | File uploads / profile avatars |
| Validation and RFC 7807-style consistent errors | Real-time WebSockets |
| Offset pagination with list previews | Native-mobile sync protocol / conflict CRDTs |
| Protected system catalog + user custom types | Admin user directory |

## 3. Base URL and Versioning

- **Production**: `https://api.workout-tracker.com/v1`
- **Development**: `http://localhost:3000/v1`
- **Versioning**: URL path (`/v1/`)

## 4. Authentication & Security

- **Dual-Auth Support**:
  - **Bearer JWT**: `Authorization: Bearer <token>` for API clients, external integrations, or mobile apps.
  - **HttpOnly Cookie**: SameSite `Lax`/`Strict` cookie containing signed session token for web browsers (shields single-page web app against XSS token harvesting).
- **Public endpoints**: `POST /auth/login`, `POST /users` (registration).
- **Protected endpoints**: All other endpoints require a valid session/token.
- **Identity on writes**: `user_id` is extracted strictly from the verified token/session. Payloads never accept a client-provided `user_id`.
- **Expiry**: 24 hours. Refresh tokens are out of scope for the 1-week MVP; expired sessions re-authenticate.
- **Logout**: Client discards JWT; cookie is cleared via `POST /auth/logout` with `Max-Age=0`.

## 5. HTTP Methods and Status Codes

| Method | Use |
|--------|-----|
| `GET` | Read single resource or paginated collection |
| `POST` | Create resource (or nested resource tree) |
| `PUT` | Full replacement / atomic update of resource |
| `DELETE` | Remove resource |

| Status | When |
|--------|------|
| `200 OK` | Successful GET / PUT |
| `201 Created` | Successful POST |
| `204 No Content` | Successful DELETE / logout |
| `400 Bad Request` | Validation failure (malformed JSON, invalid fields) |
| `401 Unauthorized` | Missing, expired, or invalid authentication credentials |
| `403 Forbidden` | Valid credentials, but attempting to mutate system catalog or another user's data |
| `404 Not Found` | Resource does not exist or belongs to another user |
| `409 Conflict` | Unique constraint violation (email, exercise name) or deleting in-use exercise |
| `422 Unprocessable` | Semantic constraint violation (e.g. `ended_at < started_at`, negative reps) |
| `429 Too Many Requests` | Rate limit exceeded |
| `500 Internal Server Error` | Unexpected server failure |

## 6. Data Formats

- JSON request and response; `Content-Type: application/json`
- Timestamps: ISO 8601 with offset, e.g. `2026-09-02T18:00:00-04:00`
- Weight units: `'kg'` or `'lbs'` only. Bodyweight sets send `"weight": null`.
- Warmup sets: `"is_warmup": true` (default `false`).

## 7. Pagination & Collection Envelopes

List endpoints return a standardized envelope:

```json
{
  "items": [],
  "total": 25,
  "limit": 20,
  "offset": 0
}
```

### 7.1 Session List Preview (< 1-Week UX Optimization)
To allow a mobile web app to display a rich workout feed without making N+1 queries, `GET /sessions` items include summary metadata:
```json
{
  "session_id": 42,
  "started_at": "2026-09-02T17:30:00Z",
  "ended_at": "2026-09-02T18:45:00Z",
  "duration_minutes": 75.0,
  "notes": "Chest & Arms",
  "exercise_count": 4,
  "total_sets": 14,
  "exercise_names_preview": "Bench Press, Overhead Press, Bicep Curl, Tricep Extension",
  "working_volume": 14250.0,
  "primary_unit": "lbs"
}
```

## 8. Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "ended_at",
      "reason": "ended_at must be greater than or equal to started_at"
    }
  }
}
```

## 9. Rate Limiting

- Authenticated: 1,000 requests / hour / user
- Anonymous (login + register): 100 requests / hour / IP
- Headers: `X-RateLimit-Remaining`, `X-RateLimit-Reset`

## 10. Endpoints Summary

| Resource | Create | Read List | Read One | Update | Delete |
|----------|--------|-----------|----------|--------|--------|
| Auth | POST /auth/login<br>POST /auth/logout | — | — | — | — |
| Users | POST /users | — | GET /users/me | PUT /users/me | DELETE /users/me |
| Workout Types | POST /workout-types | GET /workout-types | GET /workout-types/{id} | PUT /workout-types/{id} | DELETE /workout-types/{id} |
| Sessions | POST /sessions | GET /sessions | GET /sessions/{id} | PUT /sessions/{id} | DELETE /sessions/{id} |
| Workouts | POST /workouts | GET /workouts?session_id= | GET /workouts/{id} | PUT /workouts/{id} | DELETE /workouts/{id} |
| Sets | POST /workout-sets | GET /workout-sets?workout_id= | GET /workout-sets/{id} | PUT /workout-sets/{id} | DELETE /workout-sets/{id} |

### 10.1 Workout Types (Catalog & Custom)
- `GET /workout-types`: Returns all default system exercises (`is_custom: false`) plus the caller's custom exercises (`is_custom: true`).
- `POST /workout-types`: Creates a new custom workout type scoped to the caller (`user_id = token.user_id`).
- `PUT /workout-types/{id}` and `DELETE /workout-types/{id}`: Only permitted for user's own custom exercises. Modifying or deleting system exercises returns `403 Forbidden`. Deleting a custom exercise referenced in workouts returns `409 Conflict`.

### 10.2 Sessions: Atomic Create & Atomic Update
- **Atomic Create (`POST /sessions`)**: Creates session, workout blocks, and sets in one database transaction.
- **Atomic Update (`PUT /sessions/{id}`)**: Updates session metadata (`started_at`, `ended_at`, `notes`) and atomically replaces or updates child workouts and sets. This guarantees that clicking "Save Session" in the web UI is a single reliable HTTP request.
- **`GET /sessions/{id}`**: Returns session detail with child `workouts` ordered by `display_order`, each containing child `sets` ordered by `set_number`.

## 11. Security & Production Checklist

- Passwords hashed with bcrypt (salt rounds >= 10) or Argon2id.
- JWT signed with secret key >= 256 bits; sub claim equals `user_id`.
- CORS configuration: restrict origins strictly to authorized web app domains.
- Parameterized SQL / ORM query building only to prevent SQL injection.
- Security headers enabled (`helmet` or Fastify security plugins).

## 12. Document History

| Version | Date | Notes |
|---------|------|--------|
| 1.0 | 2025-11 | Four resources; global JWT including login; pagination key mismatch |
| 1.1 | 2026-08-30 | Public login; `/users/me`; `workout_sets`; nested session create; `items` envelope |
| 1.2 | 2026-09-02 | Added cookie auth; `ended_at` duration; `is_warmup` flag; atomic session updates (`PUT /sessions/{id}`); session list summary preview; custom exercise security |
