# Architecture 1: TanStack Full-Stack with Direct Database Access

**Document Version**: 1.0  
**Date**: 2026-09-02  
**Target Milestone**: Production Web Application in < 1 Week  
**Stack**: TanStack Start (React 19, TanStack Router, Vinxi/Nitro), Drizzle ORM, PostgreSQL 14+, Tailwind CSS + shadcn/ui

---

## 1. Executive Summary

This architecture implements a unified, full-stack TypeScript web application using **TanStack Start** (the official full-stack framework built on TanStack Router and React Server Functions). The application directly queries PostgreSQL using a type-safe ORM (**Drizzle ORM**), eliminating the requirement for a separate standalone backend service, custom REST controllers, or manual API serializations.

By co-locating route definitions, data loaders, and server mutations inside a single codebase, this architecture minimizes boilerplate and maximizes developer velocity, making it an ideal choice for shipping a polished, responsive workout tracker within a strict 1-week timeline.

---

## 2. System Topology & Data Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│ Browser (Mobile 360-430px & Desktop Viewports)                         │
│                                                                        │
│  ┌───────────────────────┐          ┌───────────────────────────────┐  │
│  │ TanStack Router Cache │          │ Active Workout Session State  │  │
│  │ (SWR Loaders)         │          │ (Set Grid, Timer, Inputs)     │  │
│  └───────────▲───────────┘          └───────────────┬───────────────┘  │
└──────────────┼──────────────────────────────────────┼──────────────────┘
               │                                      │
               │ HTTP GET (SSR/Streamed JSON)         │ HTTP POST (RPC Server Function)
               │                                      │
┌──────────────▼──────────────────────────────────────▼──────────────────┐
│ TanStack Start Server Runtime (Node.js / Nitro Engine)                 │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Authentication & Authorization Middleware                         │  │
│  │ - Validates HttpOnly, SameSite Session Cookie                     │  │
│  │ - Injects authenticated user context ({ userId: bigint })        │  │
│  └──────────────────────────────────┬───────────────────────────────┘  │
│                                     │                                  │
│  ┌──────────────────────────────────▼───────────────────────────────┐  │
│  │ Route Loaders & Server Functions (createServerFn)                │  │
│  │ - routes/sessions/index.tsx -> listUserSessionsQuery()           │  │
│  │ - routes/sessions/$id.tsx   -> getSessionDetailQuery()           │  │
│  │ - fn/saveSession.ts         -> saveSessionAtomic()               │  │
│  └──────────────────────────────────┬───────────────────────────────┘  │
│                                     │                                  │
│  ┌──────────────────────────────────▼───────────────────────────────┐  │
│  │ Data Layer (Drizzle ORM + postgres.js Connection Pool)           │  │
│  │ - Direct SQL queries with single-roundtrip JSON aggregation       │  │
│  │ - Zero N+1 query overhead                                        │  │
│  └──────────────────────────────────┬───────────────────────────────┘  │
└─────────────────────────────────────┼──────────────────────────────────┘
                                      │
                                      ▼
                        ┌───────────────────────────┐
                        │ PostgreSQL 14+ Database   │
                        │ (localhost:5433 / RDS)    │
                        └───────────────────────────┘
```

---

## 3. Technology Stack Breakdown

| Layer | Technology | Rationale for 1-Week Delivery |
|-------|------------|-------------------------------|
| **Framework** | **TanStack Start** | Full-stack React 19 powered by TanStack Router and Nitro/Vite. Native Server Functions (`createServerFn`) eliminate API routing boilerplate. |
| **Routing** | **TanStack Router** | Built-in file-based routing, 100% type-safe search parameters (e.g. `?limit=20&offset=0`), nested layouts, and automatic route prefetching. |
| **Data Access** | **Drizzle ORM + postgres.js** | Thin, zero-overhead TypeScript ORM that mirrors PostgreSQL schema 1:1. Supports direct parameterized SQL and single-query JSON aggregations. |
| **Authentication** | **HttpOnly Cookie Sessions (Lucia / Jose)** | Signed, secure session cookies. Eliminates XSS vulnerabilities common with localStorage JWTs; no manual `Authorization: Bearer` headers in client code. |
| **Validation** | **Zod** | Shared schemas between UI forms and server mutations. Guarantees compile-time and runtime validation parity. |
| **Styling & UI** | **Tailwind CSS + shadcn/ui** | Accessible, headless primitives (Dialog, Select, Dropdown, Button) ready for quick mobile-first composition. |

---

## 4. Key Architectural Patterns

### 4.1 Server Functions (`createServerFn`) for Atomic Mutations
Instead of maintaining separate Express/NestJS endpoints and Axios wrappers, mutations are defined as type-safe server functions that can be invoked directly from React components:

```typescript
// app/server/session-actions.ts
import { createServerFn } from '@tanstack/start';
import { z } from 'zod';
import { db } from './db';
import { sessions, workouts, workoutSets } from './db/schema';
import { getAuthContext } from './auth';

const SessionPayloadSchema = z.object({
  sessionId: z.number().optional(),
  startedAt: z.string().datetime(),
  endedAt: z.string().datetime().nullable().optional(),
  notes: z.string().max(1000).optional(),
  exercises: z.array(z.object({
    workoutTypeId: z.number(),
    displayOrder: z.number(),
    notes: z.string().optional(),
    sets: z.array(z.object({
      setNumber: z.number().int().positive(),
      reps: z.number().int().positive(),
      weight: z.number().nullable(),
      weightUnit: z.enum(['kg', 'lbs']),
      isWarmup: z.boolean().default(false)
    }))
  }))
});

export const saveSessionFn = createServerFn({ method: 'POST' })
  .validator((data) => SessionPayloadSchema.parse(data))
  .handler(async ({ data, context }) => {
    const { userId } = await getAuthContext();

    // Atomic transaction: updates session metadata and synchronizes exercises and sets
    return await db.transaction(async (tx) => {
      let targetSessionId = data.sessionId;

      if (!targetSessionId) {
        const [inserted] = await tx.insert(sessions).values({
          userId,
          startedAt: new Date(data.startedAt),
          endedAt: data.endedAt ? new Date(data.endedAt) : null,
          notes: data.notes
        }).returning({ id: sessions.sessionId });
        targetSessionId = inserted.id;
      } else {
        await tx.update(sessions).set({
          startedAt: new Date(data.startedAt),
          endedAt: data.endedAt ? new Date(data.endedAt) : null,
          notes: data.notes,
          updatedAt: new Date()
        }).where(and(eq(sessions.sessionId, targetSessionId), eq(sessions.userId, userId)));

        // Remove previous workout blocks to replace with the new atomic snapshot
        await tx.delete(workouts).where(eq(workouts.sessionId, targetSessionId));
      }

      for (const ex of data.exercises) {
        const [insertedWorkout] = await tx.insert(workouts).values({
          sessionId: targetSessionId,
          workoutTypeId: ex.workoutTypeId,
          displayOrder: ex.displayOrder,
          notes: ex.notes
        }).returning({ id: workouts.workoutId });

        if (ex.sets.length > 0) {
          await tx.insert(workoutSets).values(
            ex.sets.map((s) => ({
              workoutId: insertedWorkout.id,
              setNumber: s.setNumber,
              reps: s.reps,
              weight: s.weight?.toString(),
              weightUnit: s.weightUnit,
              isWarmup: s.isWarmup
            }))
          );
        }
      }

      return { success: true, sessionId: targetSessionId };
    });
  });
```

### 4.2 Single-Roundtrip Data Loading via JSON Aggregation
Using TanStack Router's `loader`, the page loads all required data (session metadata, exercises, and sets) in **one database roundtrip** without N+1 query cascades:

```typescript
// app/routes/sessions/$sessionId.tsx
import { createFileRoute } from '@tanstack/react-router';
import { sql } from 'drizzle-orm';
import { db } from '~/server/db';
import { getAuthContext } from '~/server/auth';

export const Route = createFileRoute('/sessions/$sessionId')({
  loader: async ({ params }) => {
    const { userId } = await getAuthContext();
    const sessionId = Number(params.sessionId);

    const result = await db.execute(sql`
      SELECT
        s.session_id,
        s.started_at,
        s.ended_at,
        s.notes,
        COALESCE(
          json_agg(
            json_build_object(
              'workout_id', w.workout_id,
              'workout_type_id', wt.workout_type_id,
              'name', wt.name,
              'display_order', w.display_order,
              'notes', w.notes,
              'sets', (
                SELECT COALESCE(
                  json_agg(
                    json_build_object(
                      'workout_set_id', ws.workout_set_id,
                      'set_number', ws.set_number,
                      'reps', ws.reps,
                      'weight', ws.weight,
                      'weight_unit', ws.weight_unit,
                      'is_warmup', ws.is_warmup
                    ) ORDER BY ws.set_number
                  ), '[]'::json
                )
                FROM workout_sets ws
                WHERE ws.workout_id = w.workout_id
              )
            ) ORDER BY w.display_order
          ) FILTER (WHERE w.workout_id IS NOT NULL),
          '[]'::json
        ) AS exercises
      FROM sessions s
      LEFT JOIN workouts w ON s.session_id = w.session_id
      LEFT JOIN workout_types wt ON w.workout_type_id = wt.workout_type_id
      WHERE s.session_id = ${sessionId} AND s.user_id = ${userId}
      GROUP BY s.session_id;
    `);

    if (result.rows.length === 0) {
      throw new Response('Session Not Found', { status: 404 });
    }

    return result.rows[0];
  }
});
```

---

## 5. Directory Structure for Fast 1-Week Delivery

```
app/
├── routes/                      # TanStack file-based routes
│   ├── __root.tsx               # Root layout (Nav, Toast container, Theme)
│   ├── index.tsx                # Dashboard: streak, recent activity, quick CTA
│   ├── login.tsx                # Auth: sign-in form
│   ├── register.tsx             # Auth: registration form
│   ├── sessions/
│   │   ├── index.tsx            # Paginated history feed with summary cards
│   │   ├── new.tsx              # Active gym logging screen (interactive set grid)
│   │   └── $sessionId.tsx       # Session view / edit / delete
│   ├── exercises/
│   │   └── index.tsx            # Exercise catalog & custom exercise manager
│   └── account.tsx              # User profile & settings
├── components/                  # UI Components
│   ├── ui/                      # shadcn primitives (button, dialog, input, card)
│   ├── session-logger.tsx       # Live set grid with numeric inputs & rest timer
│   ├── exercise-picker.tsx      # Fast search-as-you-type modal for exercises
│   └── set-row.tsx              # Individual row: set #, weight, reps, warmup toggle
├── server/                      # Server-only execution layer
│   ├── db/
│   │   ├── index.ts             # postgres.js + Drizzle client instance
│   │   └── schema.ts            # Drizzle schema matching minimal schema.sql
│   ├── auth.ts                  # Cookie session handling (Jose / Argon2id)
│   └── session-actions.ts       # Server functions for atomic saves and deletes
├── styles/
│   └── globals.css              # Tailwind configuration
└── router.tsx                   # TanStack Router instance creation
```

---

## 6. One-Week Implementation Plan

| Day | Milestone Focus | Deliverables |
|:---:|-----------------|--------------|
| **Day 1** | **Setup & Foundation** | Initialize TanStack Start template, configure Tailwind + shadcn/ui, connect Drizzle ORM to PostgreSQL schema. Seed database. |
| **Day 2** | **Authentication & Shell** | Implement password hashing (Argon2), login/register forms, session cookie creation, authenticated layout shell with responsive mobile bottom bar. |
| **Day 3** | **Exercise Catalog & Picker** | Implement `GET /exercises` query (system defaults + user custom), search-as-you-type exercise picker component, custom exercise creation modal. |
| **Day 4** | **Primary Session Logger UI** | Build the `/sessions/new` interactive set-logging interface: dynamic exercise addition, set adder, numeric keypad formatting, warmup toggle, rest timer. |
| **Day 5** | **Atomic Save & History Feed** | Implement `saveSessionFn` atomic transaction. Build `/sessions` paginated history feed with exercise preview chips, duration, and volume calculation. |
| **Day 6** | **Session Editing & Quick Stats** | Build `/sessions/$sessionId` edit flow. Add previous workout set auto-fill and estimated 1RM quick stats display. |
| **Day 7** | **Polish, Testing & Deployment** | Mobile ergonomics testing (iPhone/Android browser chrome check), error boundary verification, Dockerfile packaging or single-click deployment to Node.js host (Render/Fly.io). |

---

## 7. Objective Pros & Cons Analysis

### Advantages (Pros)

1. **Maximum Velocity for < 1-Week Delivery**:
   Eliminates all intermediary API layers. There are no NestJS controllers, services, DTO classes, or OpenAPI codegen pipelines to maintain. Writing a server function takes under 3 minutes.
2. **Zero Client-Server Drift (Single-Process Type Safety)**:
   Database models, Zod validation schemas, and UI components share identical TypeScript types natively. Changing a column in Drizzle immediately flags type errors across all UI forms at compile time.
3. **Optimized Latency & Minimal Network Overhead**:
   Data loaders run server-side right next to PostgreSQL. Queries fetch directly via connection pools without serializing into HTTP JSON across internal microservice networks.
4. **Superior Security Posture by Default**:
   Authentication tokens are kept inside encrypted `HttpOnly`, `SameSite=Lax` cookies managed directly by server middleware. The browser JavaScript execution context never touches raw auth tokens, neutralizing XSS credential theft.
5. **Unified Deployment & Lower Operational Cost**:
   The entire application compiles into a single deployable Node.js container or serverless bundle. There is only one server process to monitor, scale, and log.

### Disadvantages (Cons)

1. **Tight Coupling to Web**:
   Because server functions are tailored to the web UI's component tree, they do not expose a public REST contract. If an iOS or Android native app is developed later, a dedicated REST API will need to be added or exposed.
2. **Framework Maturity**:
   TanStack Start is rapidly maturing. While TanStack Router and TanStack Query are industry battle-tested, TanStack Start's SSR bundling conventions can occasionally have breaking changes between minor versions compared to established frameworks.
3. **Server Load on Heavy Rendering**:
   Server-side rendering and loader execution run on the web server CPU. For a lightweight personal workout tracker, this overhead is negligible, but for millions of concurrent users, decoupling static assets from API compute can be easier to scale independently.
