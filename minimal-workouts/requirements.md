# Weight Training Workout Tracker — Minimal Requirements

**Document version**: 1.2  
**Last updated**: 2026-09-02  
**Status**: Requirements specification for a rapid MVP web workout tracker (< 1 week build)

## 1. Executive Summary

The Weight Training Workout Tracker is a lean, responsive web application for logging resistance training sessions. A user records training sessions, exercises, and **individual sets** (reps, weight, unit, warmup flag). It prioritizes rapid entry at the gym, low cognitive load, and clean data integrity.

This document describes the **minimal** variant (`minimal-workouts/`). It intentionally avoids analytics bloat, social feeds, and native app overhead to guarantee a complete, production-ready release in under one week. The broader long-term product vision lives in `requirements/comprehensive.md` and `comprehensive-workouts/`.

## 2. System Overview

### 2.1 Purpose

Give an athlete an immediate, friction-free way to log barbell, dumbbell, cable, and bodyweight training: which exercises, which sets, what load, and track duration.

### 2.2 Target Users

- Individuals logging their own workouts on a phone browser or desktop
- Lifters who want clean, accurate history and personal records without cumbersome multi-step wizards

### 2.3 Platform & Delivery Scope (< 1 Week Target)

| In Scope (1-Week MVP) | Deferred (Post-MVP) |
|-----------------------|---------------------|
| Responsive mobile/desktop web application | Native iOS / Android apps |
| Direct DB or REST API + PostgreSQL | Offline storage and background sync |
| Single-user authentication (JWT & HttpOnly Session Cookie) | Cross-device offline conflict resolution |
| Shared system catalog + user custom exercises | Social feeds, followers, comments |
| Set-by-set logging (reps, weight, unit, warmup flag) | Barcode scanner / plate calculator |
| Atomic session create/update (single save action) | Heart rate / wearable Bluetooth integration |
| Session duration tracking (`started_at` & `ended_at`) | Cardio GPS maps / complex EAV metrics |

---

## 3. Functional Requirements

### 3.1 User Management

#### 3.1.1 Registration and Authentication
- **FR-001**: Users must be able to register with email, name, and password.
- **FR-002**: Users must be able to log in securely. Authentication must support Bearer JWT and/or HttpOnly session cookies (for web SPA / SSR security against XSS). Logout invalidates or discards client auth tokens.
- **FR-003**: Authenticated requests derive user identity strictly from the validated session/token, never from client-supplied `user_id` payload fields.

#### 3.1.2 Profile
- **FR-004**: A user has a name and email. Email is unique, normalized (lowercase, trimmed), and validated.

### 3.2 Session Management

- **FR-005**: Users must be able to start, edit, and finish a workout session.
- **FR-006**: A session records **start time** (`started_at`, timezone-aware) and optional **end time** (`ended_at`, timezone-aware) to track workout duration and active session state.
- **FR-007**: A session supports optional notes (e.g., gym location, sleep, energy level).
- **FR-016**: Users may update or delete their own sessions. Deleting a session cascades to its exercise blocks and sets.
- **FR-019 (New)**: Atomic session updates: Users can edit an entire session (notes, exercise order, sets) and save in a single atomic transaction rather than firing individual requests per set.

### 3.3 Workout & Exercise Management

#### 3.3.1 Exercise Catalog & Custom Exercises
- **FR-008**: The system provides a **curated default catalog** of standard compound and isolation movements (Squat, Bench Press, Deadlift, Overhead Press, Barbell Row, Pull-ups, etc.).
- **FR-009**: Users select exercises from the catalog when building a workout.
- **FR-017 (Security update)**: Default system catalog exercises are **immutable and protected**; standard users cannot delete or rename them. Users may create **personal custom exercises** (`user_id` scoped) visible only to them.
- **FR-020**: Deleting a custom workout type that is referenced in historical sessions is rejected (`ON DELETE RESTRICT`) to preserve historical accuracy.

#### 3.3.2 Exercise Blocks and Sets
- **FR-010**: For each exercise in a session, users record:
  - Workout type / exercise reference
  - Display order within the session
  - Optional exercise notes
  - One or more **sets**, each with:
    - Set number (1-based index)
    - Repetitions (integer > 0)
    - Weight (numeric, optional; `NULL` for bodyweight)
    - Weight unit (`kg` or `lbs`)
    - Warmup indicator (`is_warmup`: boolean, default `false`)
- **FR-010a**: Different weight and reps across sets are fully supported (pyramid sets, drop sets, warmups, backoff sets).
- **FR-010b**: Warmup sets are tagged (`is_warmup = true`) so calculations for working volume and PRs do not skew user analytics.
- **FR-018**: The same workout type may appear more than once in a single session (e.g., Bench Press warm-up and Bench Press back-off block).

### 3.4 Data Viewing & History

- **FR-011**: Users must be able to list their past sessions (newest first) with pagination and optional date filters (`start_date`, `end_date`).
- **FR-011a (Performance)**: The session list endpoint includes aggregate preview data (exercise count, exercise names preview, set count, duration) so the list view loads in a single request without N+1 queries.
- **FR-012**: Opening a session displays all exercises in display order with all set details (weight, reps, warmup status).
- **FR-021 (Quick Insights)**: Quick exercise summary query showing the user's latest performance on a given exercise to inform load selection for the current session.

---

## 4. Data Model Summary

See `database/schema.md` and `database/schema.sql` for full DDL and constraint definitions.

- **`users`**: `user_id` (PK), `name`, `email`, `password_hash`, `created_at`, `updated_at`.
- **`workout_types`**: `workout_type_id` (PK), `user_id` (nullable FK → `users`, NULL for system defaults), `name`, `description`, `created_at`, `updated_at`.
- **`sessions`**: `session_id` (PK), `user_id` (FK → `users`), `started_at`, `ended_at` (nullable), `notes`, `created_at`, `updated_at`.
- **`workouts`**: `workout_id` (PK), `session_id` (FK → `sessions`), `workout_type_id` (FK → `workout_types`), `display_order`, `notes`, `created_at`, `updated_at`.
- **`workout_sets`**: `workout_set_id` (PK), `workout_id` (FK → `workouts`), `set_number`, `reps`, `weight`, `weight_unit`, `is_warmup`, `created_at`, `updated_at`.

---

## 5. Non-Functional Requirements

### 5.1 Performance
- **NFR-001**: Interactive UI actions (saving a session, completing a set, loading history) must respond within 500ms on broadband and < 1.5s on mobile 4G.
- **NFR-002**: Database queries must avoid N+1 waterfalls; session details must be fetchable in a single query via joins or JSON aggregation.

### 5.2 Security
- **NFR-003**: Passwords hashed with bcrypt (cost factor >= 10) or Argon2id.
- **NFR-004**: Strict tenant isolation: users can only read, update, or delete their own sessions and custom exercises.
- **NFR-005**: Protection against XSS and CSRF: authentication tokens sent via HttpOnly, SameSite cookies or Authorization Bearer header; TLS enforced in production.

### 5.3 Usability & Mobile Ergonomics
- **NFR-006**: Frictionless gym logging: single-screen logging experience with fast numeric keypad inputs for weight and reps.
- **NFR-007**: Responsive design optimized for mobile viewports (360px - 430px) as well as desktop browsers.

---

## 6. Document History

| Version | Date | Notes |
|---------|------|--------|
| 1.0 | 2025-11 | Initial four-table model; naive `session_date`; native mobile in scope |
| 1.1 | 2026-08-30 | Per-set table; `started_at`; audit timestamps; mobile deferred |
| 1.2 | 2026-09-02 | Added `ended_at` for workout duration; added `is_warmup` flag; isolated custom exercises from system catalog; added atomic session sync requirements for < 1 week web MVP |
