# Weight Training Workout Tracker - API Requirements

## 1. Purpose

This document defines the RESTful API for the Weight Training Workout Tracker, providing CRUD operations for:

- Users (registration, authentication)
- Workout Types (exercise definitions)
- Sessions (workout sessions)
- Workouts (individual exercises within sessions)

## 2. Scope

| In Scope | Out of Scope |
|----------|-------------|
| Full CRUD for all entities | Advanced analytics |
| User authentication (JWT) | Social features |
| Basic validation and error handling | File uploads |
| OpenAPI specification | Real-time updates |
| Pagination for list endpoints | Third-party integrations |

## 3. Base URL & Versioning

- **Base URL**: `https://api.workout-tracker.com/v1`
- **Versioning**: URL path versioning (`/v1/`)
- **Development**: `http://localhost:3000/v1`

## 4. Authentication

- **Method**: Bearer Token (JWT)
- **Login Endpoint**: `POST /auth/login`
- **Protected Routes**: All endpoints except user registration

## 5. HTTP Methods & Status Codes

### Standard HTTP Methods
- `GET` - Retrieve resources
- `POST` - Create new resources
- `PUT` - Update existing resources
- `DELETE` - Remove resources

### Standard Status Codes
- `200 OK` - Successful GET/PUT
- `201 Created` - Successful POST
- `204 No Content` - Successful DELETE
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing/invalid authentication
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `500 Internal Server Error` - Server error

## 6. Data Formats

- **Request/Response Format**: JSON
- **Content-Type**: `application/json`
- **Date Format**: ISO 8601 (`2025-11-11T10:00:00Z`)
- **Weight Units**: `kg` or `lbs`

## 7. Pagination

For list endpoints that may return many results:

- **Query Parameters**:
  - `limit` (integer, default: 10, max: 100)
  - `offset` (integer, default: 0)
- **Response Format**:
  ```json
  {
    "items": [...],
    "total": 25,
    "limit": 10,
    "offset": 0
  }
  ```

## 8. Error Handling

All errors return a consistent JSON format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    }
  }
}
```

## 9. Rate Limiting

- **Authenticated Users**: 1000 requests per hour
- **Anonymous Users**: 100 requests per hour
- **Headers**: `X-RateLimit-Remaining`, `X-RateLimit-Reset`

## 10. API Endpoints Summary

| Entity | Create | Read (List) | Read (Single) | Update | Delete |
|--------|--------|-------------|---------------|--------|--------|
| Users | POST /users | GET /users | GET /users/{id} | PUT /users/{id} | DELETE /users/{id} |
| Workout Types | POST /workout-types | GET /workout-types | GET /workout-types/{id} | PUT /workout-types/{id} | DELETE /workout-types/{id} |
| Sessions | POST /sessions | GET /sessions | GET /sessions/{id} | PUT /sessions/{id} | DELETE /sessions/{id} |
| Workouts | POST /workouts | GET /workouts | GET /workouts/{id} | PUT /workouts/{id} | DELETE /workouts/{id} |

## 11. Security Considerations

- All passwords hashed with bcrypt
- JWT tokens expire after 24 hours
- HTTPS required in production
- Input validation and sanitization
- SQL injection prevention
- CORS configuration for web/mobile clients