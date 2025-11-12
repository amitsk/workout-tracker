# **Workout & Activity Tracker – REST API Requirements Document**  
*Version 1.0 | November 01, 2025*

---

## 1. Purpose

This document defines the **RESTful API** for the **universal activity tracking system**, enabling **CRUD operations** across all entities in the database:

- `activity_category`, `activity_type`, `activity_subtype`
- `unit`, `app_user`, `activity_session`, `activity_metric`
- `activity_type_metric_template`

The API must be **secure**, **scalable**, **versioned**, and **extensible**.

---

## 2. Scope

| In Scope | Out of Scope |
|--------|-------------|
| Full CRUD for all entities | OAuth2 / SSO |
| Session + metric batch operations | Real-time WebSocket |
| Validation, error handling | Mobile push |
| OpenAPI spec | GraphQL |
| Rate limiting & pagination | File uploads (photos) |

---

## 3. Base URL & Versioning

```text
Base URL: https://api.activitytracker.com
Version:  /api/v1
```

All endpoints: `/api/v1/...`

---

## 4. Authentication & Authorization

| Method | Details |
|-------|--------|
| **Auth** | JWT Bearer Token in `Authorization` header |
| **Token Endpoint** | `POST /auth/login` (out of scope) |
| **User Context** | `user_id` from JWT claim |
| **RBAC** | 
- `USER`: Own data only  
- `ADMIN`: All data + config |

---

## 5. Common Response Format

```json
{
  "data": { ... },
  "meta": {
    "timestamp": "2025-04-05T18:00:00Z",
    "request_id": "abc123",
    "pagination": { "page": 1, "limit": 20, "total": 150 }
  },
  "error": null
}
```

**Error Response:**
```json
{
  "data": null,
  "meta": { ... },
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid metric name",
    "details": ["'reps' must be > 0"]
  }
}
```

---

## 6. CRUD Endpoints

| Entity | Method | Endpoint | Description |
|--------|--------|----------|-----------|
| **Activity Category** | GET | `/categories` | List all |
| | GET | `/categories/:id` | Get one |
| | POST | `/categories` | Create (admin) |
| | PATCH | `/categories/:id` | Update (admin) |
| | DELETE | `/categories/:id` | Delete (admin) |

---

### **POST /categories** (Admin)
```json
{
  "name": "Cognitive",
  "description": "Mental activities"
}
```
**Response (201):**
```json
{ "id": 2, "name": "Cognitive", ... }
```

---

## 7. Activity Type & Subtype

| Method | Endpoint | Notes |
|--------|----------|-------|
| GET | `/activity-types` | `?category=Physical` |
| GET | `/activity-types/:id` | Includes subtypes & templates |
| POST | `/activity-types` | Admin |
| PATCH | `/activity-types/:id` | |
| DELETE | `/activity-types/:id` | Cascade subtypes |

---

### **GET /activity-types**
```json
[
  {
    "id": 1,
    "name": "Weights",
    "category": "Physical",
    "subtypes": ["Bench Press", "Squats"],
    "metric_templates": [
      { "name": "sets", "required": true },
      { "name": "weight", "unit": "kg", "required": true }
    ]
  }
]
```

---

## 8. Activity Session (Core)

| Method | Endpoint | Description |
|--------|----------|-----------|
| POST | `/sessions` | Log new session |
| GET | `/sessions` | List user sessions |
| GET | `/sessions/:id` | Get with metrics |
| PATCH | `/sessions/:id` | Update (within 24h) |
| DELETE | `/sessions/:id` | Soft delete |

---

### **POST /sessions**
```json
{
  "activity_type_id": 1,
  "activity_subtype_id": 10,
  "started_at": "2025-04-05T18:00:00Z",
  "ended_at": "2025-04-05T18:45:00Z",
  "location": "Gym",
  "mood_before": "focused",
  "mood_after": "pumped",
  "notes": "New PR!",
  "metrics": [
    { "name": "sets", "value": 4 },
    { "name": "reps", "value": 10 },
    { "name": "weight", "value": 100, "unit": "kg" }
  ]
}
```

**Validation:**
- `started_at` < `ended_at`
- `activity_type_id` exists
- `metrics` match template (if required)

---

### **GET /sessions**
Query Params:
```text
?start=2025-04-01
&end=2025-04-30
&type=Weights
&subtype=Bench+Press
&page=1
&limit=20
&sort=started_at:desc
```

**Response:**
```json
{
  "data": [
    {
      "id": 101,
      "type": "Weights",
      "subtype": "Bench Press",
      "duration_minutes": 45,
      "started_at": "2025-04-05T18:00:00Z",
      "metrics": {
        "sets": 4,
        "weight": { "value": 100, "unit": "kg" }
      },
      "pr": true
    }
  ],
  "meta": { "pagination": { ... } }
}
```

---

## 9. Metrics (EAV)

| Method | Endpoint | Notes |
|--------|----------|-------|
| GET | `/sessions/:id/metrics` | |
| POST | `/sessions/:id/metrics` | Add metric |
| PATCH | `/metrics/:id` | Update |
| DELETE | `/metrics/:id` | |

> **Note**: Metrics are **batch-created** in `POST /sessions`

---

## 10. Units & Templates

| Entity | Endpoint | Access |
|--------|----------|--------|
| Units | `GET /units` | Public |
| Templates | `GET /activity-types/:id/templates` | Public |
| | `POST /templates` | Admin |

---

## 11. Analytics Endpoints

| Endpoint | Method | Description |
|--------|--------|-----------|
| `/progress/:type_id` | GET | Max metric per month |
| `/pr/:subtype_id` | GET | Personal record |
| `/streaks` | GET | Current & longest streak |
| `/volume` | GET | Weekly volume (sets×reps×weight) |

---

### **GET /progress/1?metric=weight**
```json
{
  "data": [
    { "month": "2025-03", "max": 90 },
    { "month": "2025-04", "max": 100 }
  ],
  "pr": 100,
  "improvement": "+11.1%"
}
```

---

## 12. Error Codes

| Code | HTTP | Meaning |
|------|------|--------|
| `VALIDATION_ERROR` | 400 | Input invalid |
| `NOT_FOUND` | 404 | Resource missing |
| `FORBIDDEN` | 403 | No access |
| `CONFLICT` | 409 | Duplicate |
| `RATE_LIMIT` | 429 | Too many requests |

---

## 13. Rate Limiting

| User Type | Limit |
|---------|-------|
| Free | 100 req/min |
| Premium | 1000 req/min |
| Admin | Unlimited |

---

## 14. OpenAPI Specification

```yaml
openapi: 3.0.3
info:
  title: Activity Tracker API
  version: 1.0.0
  description: Universal activity tracking
servers:
  - url: https://api.activitytracker.com/api/v1
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
security:
  - bearerAuth: []
```

> Full spec in `api/openapi.yaml`

---

## 15. Testing Requirements

| Type | Coverage |
|------|----------|
| Unit | 90% |
| Integration | DB + API |
| E2E | Postman/Newman |
| Load | 10k RPS |

---

## 16. Deployment

| Environment | URL |
|-----------|-----|
| Dev | `dev-api.activitytracker.com` |
| Staging | `staging-api...` |
| Prod | `api.activitytracker.com` |

---

## 17. Non-Functional Requirements

| ID | Requirement |
|----|-----------|
| API-01 | **99.9% uptime** |
| API-02 | **< 200ms avg latency** |
| API-03 | **OpenAPI docs** at `/docs` |
| API-04 | **Request ID** in logs |
| API-05 | **CORS** enabled for `app.activitytracker.com` |

---

## 18. Future Extensions

| Feature | Endpoint |
|--------|----------|
| Programs | `/programs` |
| Challenges | `/challenges` |
| Social Feed | `/feed` |
| Export | `/export/csv` |

---

## 19. Approval

| Role | Name | Date | Signature |
|------|------|------|----------|
| API Architect | _ | _ | _ |
| Backend Lead | _ | _ | _ |
| Product Owner | _ | _ | _ |
| QA Lead | _ | _ | _ |

---

**End of Document**

---

**Download**: [`api-requirements.md`](#) (Copy-paste ready)

---

## Want Next?

Say:
> **"Generate OpenAPI YAML"**  
> **"Generate Gin CRUD handlers"**  
> **"Generate Postman collection"**

This API is **production-ready**, **extensible**, and **developer-friendly**.