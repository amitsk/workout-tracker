# Workout & Activity Tracker Artifacts

Extensible tracking system for **any** activity: workouts, chess, painting, etc.

## Structure
- `database/` — Full schema + seeds + analytics queries
- `diagrams/` — Mermaid ER diagram
- `api/` — REST API spec + examples
- `mobile/` — JSON models for app

## Setup
```bash
psql -f database/schema.sql
psql -f database/seed_data.sql
psql -f indexes.sql

# Database Schema

## Entities
| Table | Key Fields |
|------|------------|
| `activity_category` | `id`, `name` |
| `activity_type` | `id`, `name`, `category_id` |
| ... (see above) |

## Relationships
- One `activity_type` belongs to one `category`
- One `session` has many `metrics`
- Metrics use `unit` for type safety

> See [ER Diagram (Mermaid)](diagrams/er_diagram.mmd) for visual