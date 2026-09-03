# Architecture 2: Next.js Client SPA + NestJS & Fastify REST API

**Document Version**: 1.0  
**Date**: 2026-09-02  
**Target Milestone**: Production Web Application in < 1 Week  
**Stack**: Next.js 15 (Client SPA / Static Export + TanStack Query), NestJS 11 + Fastify (`@nestjs/platform-fastify`), TypeScript, PostgreSQL 14+

---

## 1. Executive Summary

This architecture establishes a decoupled, enterprise-grade separation of concerns:
1. **Frontend**: A client-rendered Single Page Application (SPA) built with **Next.js** (utilizing TanStack Query for caching, client-side routing, and zero SSR server complexity).
2. **Backend**: A high-throughput, standalone REST API service built with **NestJS** running on the **Fastify** engine (`@nestjs/platform-fastify`).

By separating the client from the API, the backend implements the repository's `openapi.yaml` contract directly. This setup guarantees that the API is instantly reusable for future native mobile applications (iOS/Android) or third-party integrations, while Fastify provides low latency and high request throughput.

---

## 2. System Topology & Network Architecture

```
┌────────────────────────────────────────────────────────┐
│ Client Tier: Next.js SPA (Vercel / Cloudflare Pages)   │
│                                                        │
│  ┌───────────────────────┐   ┌──────────────────────┐  │
│  │ TanStack React Query  │   │ Auth Context (JWT)   │  │
│  │ (Cache & Optimistic)  │   │ (Memory + Refresh)   │  │
│  └───────────▲───────────┘   └──────────┬───────────┘  │
│              │                          │              │
│              └───────────┬──────────────┘              │
│                          │                             │
│                  HTTP JSON with Bearer JWT             │
└──────────────────────────┼─────────────────────────────┘
                           │
                           │ Cross-Origin REST API calls
                           │ (https://api.domain.com/v1)
                           │
┌──────────────────────────▼─────────────────────────────┐
│ Backend Tier: NestJS on Fastify (Fly.io / Render / ECS)│
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Fastify Engine Plugins                           │  │
│  │ - @fastify/cors (Origin allowlist)               │  │
│  │ - @fastify/helmet (Security headers)             │  │
│  │ - @fastify/rate-limit (1000 req/hr user)         │  │
│  └──────────────────────────┬───────────────────────┘  │
│                             │                          │
│  ┌──────────────────────────▼───────────────────────┐  │
│  │ NestJS Core Application Pipeline                 │  │
│  │  - JwtAuthGuard (Passport / Fastify JWT)         │  │
│  │  - ValidationPipe (class-validator DTOs)         │  │
│  │  - HttpExceptionFilter (Consistent ErrorBody)    │  │
│  └──────────────────────────┬───────────────────────┘  │
│                             │                          │
│  ┌──────────────────────────▼───────────────────────┐  │
│  │ Domain Feature Modules                           │  │
│  │  - AuthModule      (/v1/auth)                    │  │
│  │  - UsersModule     (/v1/users)                   │  │
│  │  - TypesModule     (/v1/workout-types)           │  │
│  │  - SessionsModule  (/v1/sessions)                │  │
│  └──────────────────────────┬───────────────────────┘  │
│                             │                          │
│  ┌──────────────────────────▼───────────────────────┐  │
│  │ Data Access Layer (Drizzle / Prisma Repository)  │  │
│  │ - Parameterized PostgreSQL queries               │  │
│  └──────────────────────────┬───────────────────────┘  │
└─────────────────────────────┼──────────────────────────┘
                              │
                              ▼
                ┌───────────────────────────┐
                │ PostgreSQL 14+ Database   │
                │ (localhost:5433 / AWS RDS)│
                └───────────────────────────┘
```

---

## 3. Technology Stack Breakdown

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Frontend Framework** | **Next.js (SPA Mode)** | Rich React ecosystem, instant builds, file routing, deployable as a static SPA or edge client. |
| **Frontend Data Fetching** | **TanStack Query (@tanstack/react-query)** | Automated caching, background refetching, mutation states, optimistic UI updates. |
| **Backend Framework** | **NestJS + TypeScript** | Opinionated architectural structure (Modules, Controllers, Services, Dependency Injection) for clean codebase scaling. |
| **HTTP Engine** | **Fastify (`@nestjs/platform-fastify`)** | Up to 2x–4x higher throughput than standard Express; ultra-low overhead JSON serialization with `fast-json-stringify`. |
| **DTO Validation** | **class-validator + class-transformer** | Runtime type checking, payload sanitization, automatic schema validation against `openapi.yaml`. |
| **API Documentation** | **@nestjs/swagger** | Auto-generates interactive Swagger documentation and exports OpenAPI specs from TypeScript DTO decorators. |
| **Database Access** | **Drizzle ORM (or TypeORM)** | Fast SQL execution with clean repository encapsulation inside NestJS injectable services. |

---

## 4. Backend Implementation Details (NestJS + Fastify)

### 4.1 Bootstrap with Fastify Adapter
```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter({ logger: true })
  );

  // Global prefix matching versioning requirement
  app.setGlobalPrefix('v1');

  // Input validation pipe matching openapi requirements
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    })
  );

  // OpenAPI Swagger generation
  const config = new DocumentBuilder()
    .setTitle('Weight Training Workout Tracker API')
    .setVersion('1.2.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(3000, '0.0.0.0');
}
bootstrap();
```

### 4.2 Sessions Controller with Atomic Upsert
```typescript
// src/sessions/sessions.controller.ts
import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, ParseIntPipe } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { SessionsService } from './sessions.service';
import { CreateSessionDto, UpdateSessionDto, SessionQueryDto } from './dto/session.dto';

@Controller('sessions')
@UseGuards(JwtAuthGuard)
export class SessionsController {
  constructor(private readonly sessionsService: SessionsService) {}

  @Get()
  async listSessions(
    @CurrentUser('userId') userId: number,
    @Query() query: SessionQueryDto,
  ) {
    return this.sessionsService.listSessions(userId, query);
  }

  @Get(':id')
  async getSessionDetail(
    @CurrentUser('userId') userId: number,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.sessionsService.getSessionDetail(userId, id);
  }

  @Post()
  async createSession(
    @CurrentUser('userId') userId: number,
    @Body() dto: CreateSessionDto,
  ) {
    return this.sessionsService.createSessionAtomic(userId, dto);
  }

  @Put(':id')
  async updateSession(
    @CurrentUser('userId') userId: number,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateSessionDto,
  ) {
    return this.sessionsService.updateSessionAtomic(userId, id, dto);
  }

  @Delete(':id')
  async deleteSession(
    @CurrentUser('userId') userId: number,
    @Param('id', ParseIntPipe) id: number,
  ) {
    return this.sessionsService.deleteSession(userId, id);
  }
}
```

### 4.3 DTO Definition with Warmup and Duration Support
```typescript
// src/sessions/dto/session.dto.ts
import { IsDateString, IsOptional, IsString, IsArray, ValidateNested, IsInt, IsPositive, IsNumber, IsEnum, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';

export class WorkoutSetDto {
  @IsInt()
  @IsPositive()
  setNumber: number;

  @IsInt()
  @IsPositive()
  reps: number;

  @IsOptional()
  @IsNumber()
  weight?: number;

  @IsEnum(['kg', 'lbs'])
  weightUnit: 'kg' | 'lbs';

  @IsOptional()
  @IsBoolean()
  isWarmup?: boolean = false;
}

export class WorkoutItemDto {
  @IsInt()
  workoutTypeId: number;

  @IsOptional()
  @IsInt()
  displayOrder?: number = 0;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => WorkoutSetDto)
  sets: WorkoutSetDto[];
}

export class CreateSessionDto {
  @IsDateString()
  startedAt: string;

  @IsOptional()
  @IsDateString()
  endedAt?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => WorkoutItemDto)
  workouts?: WorkoutItemDto[];
}

export class UpdateSessionDto extends CreateSessionDto {}
```

---

## 5. Next.js SPA Frontend Implementation

The frontend is configured purely for client rendering (`"use client"` or static SPA export), utilizing TanStack Query for cache synchronization.

### 5.1 API Client Wrapper
```typescript
// frontend/src/lib/api-client.ts
import axios from 'axios';

export const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/v1',
});

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

### 5.2 React Query Hook for Active Logging
```typescript
// frontend/src/hooks/use-session-mutations.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';

export function useSaveSession() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (payload: any) => {
      if (payload.sessionId) {
        const res = await apiClient.put(`/sessions/${payload.sessionId}`, payload);
        return res.data;
      } else {
        const res = await apiClient.post('/sessions', payload);
        return res.data;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sessions'] });
    },
  });
}
```

---

## 6. Directory Structure for Monorepo / Decoupled Codebase

```
workout-tracker/
├── backend/                     # NestJS + Fastify REST API
│   ├── src/
│   │   ├── auth/                # JWT strategy, login/register controllers
│   │   ├── users/               # Current profile (/v1/users/me)
│   │   ├── workout-types/       # Catalog & custom exercise endpoints
│   │   ├── sessions/            # Atomic session logging & query logic
│   │   ├── database/            # Drizzle ORM client & schema bindings
│   │   ├── app.module.ts
│   │   └── main.ts              # Fastify bootstrap
│   ├── Dockerfile
│   └── package.json
└── frontend/                    # Next.js SPA
    ├── src/
    │   ├── app/                 # Next.js App Router (Client layout)
    │   │   ├── login/page.tsx
    │   │   ├── sessions/page.tsx
    │   │   ├── sessions/new/page.tsx
    │   │   └── layout.tsx
    │   ├── components/          # Set grid, exercise selector, timer
    │   ├── hooks/               # TanStack Query custom hooks
    │   └── lib/api-client.ts    # Axios/Ky HTTP client with JWT interceptor
    ├── next.config.ts           # output: 'export' (SPA mode)
    └── package.json
```

---

## 7. One-Week Implementation Plan

| Day | Milestone Focus | Backend (NestJS + Fastify) | Frontend (Next.js SPA) |
|:---:|-----------------|----------------------------|------------------------|
| **Day 1** | **Setup & Scaffold** | Initialize NestJS Fastify app, connect Drizzle to Postgres 16. | Create Next.js app, configure Tailwind + shadcn/ui. |
| **Day 2** | **Auth & User Profile** | Implement `POST /auth/login`, `POST /users`, `GET /users/me`. | Build Login & Registration pages with JWT storage. |
| **Day 3** | **Exercise Catalog** | Implement `GET/POST /workout-types` (system + custom logic). | Build exercise picker modal and search filter. |
| **Day 4** | **Session Logging API & UI** | Implement `POST /sessions` atomic create transaction. | Build `/sessions/new` interactive set-logging grid. |
| **Day 5** | **Session History & Previews** | Implement `GET /sessions` with exercise chips and volume preview. | Build paginated session cards feed with TanStack Query. |
| **Day 6** | **Atomic Edit & PRs** | Implement `PUT /sessions/:id` and estimated 1RM calculations. | Build session detail/edit page with auto-fill previous weights. |
| **Day 7** | **Integration & Deployment** | Containerize NestJS (Fly.io/Render); verify OpenAPI Swagger. | Deploy Next.js SPA to Vercel/Cloudflare; smoke test API. |

---

## 8. Objective Pros & Cons Analysis

### Advantages (Pros)

1. **Clean Separation of Concerns**:
   The frontend is completely decoupled from database access, SQL queries, and ORM drivers. The backend acts strictly as an API gateway and business logic enforcer.
2. **Immediate Multi-Client / Mobile Readiness**:
   Because NestJS implements standard HTTP REST endpoints with OpenAPI annotations, the exact same backend can serve an iOS app, Android app, or third-party fitness API without touching server code.
3. **High-Throughput Fastify Performance**:
   Fastify's compiled schema serialization (`fast-json-stringify`) and lightweight event loop deliver superior throughput and low memory consumption under high concurrency compared to traditional Express.
4. **Independent Scalability & Hosting Flexibility**:
   The frontend can be distributed globally as static assets across edge CDNs (Cloudflare / Vercel), while the NestJS API container runs in regions close to the PostgreSQL database.
5. **Standardized Architecture for Teams**:
   NestJS's dependency injection and modular boundaries prevent spaghetti code from accumulating as the application grows beyond the MVP.

### Disadvantages (Cons)

1. **Higher Initial Overhead for a 1-Week Timeline**:
   Requires maintaining two separate applications, two `package.json` files, duplicated type definitions (or a shared monorepo package), DTO classes, and controller routing boilerplate.
2. **Type-Drift Between Frontend and Backend**:
   Unless an automated OpenAPI-to-TypeScript code generator (e.g. `openapi-typescript` or Orval) is configured, changes to backend DTOs must be manually mirrored in the Next.js API client.
3. **CORS and Token Management Overhead**:
   Requires configuring CORS allowlists and managing Bearer token refreshing/storage on the client (or setting up cross-domain cookie proxies).
4. **Added Latency for Web SSR**:
   If SSR is enabled in the future, rendering pages on the frontend requires an extra HTTP network hop from Next.js server to NestJS API server before reaching PostgreSQL.
