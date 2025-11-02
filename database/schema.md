# Activity Tracker – Database Schema

## Overview
A flexible, extensible schema for tracking **any** activity: workouts, chess, painting, music, etc.

---

## Tables

### `activity_category`
| Field | Type | Notes |
|------|------|-------|
| id | SERIAL PK | |
| name | VARCHAR(50) | Unique |
| description | TEXT | |

### `activity_type`
| Field | Type | Notes |
|------|------|-------|
| id | SERIAL PK | |
| name | VARCHAR(100) | Unique |
| category_id | INT FK | → activity_category |
| is_physical | BOOLEAN | |
| has_duration | BOOLEAN | Default: true |
| has_intensity | BOOLEAN | |
| description | TEXT | |
| icon_url | VARCHAR(255) | |

### `activity_subtype`
| Field | Type | Notes |
|------|------|-------|
| id | SERIAL PK | |
| activity_type_id | INT FK | → activity_type |
| name | VARCHAR(100) | |
| default_sets, default_reps | INT | Optional defaults |

### `unit`
| Field | Type | Notes |
|------|------|-------|
| id | SERIAL PK | |
| name | VARCHAR(20) | e.g., 'kilograms' |
| symbol | VARCHAR(10) | 'kg' |
| type | VARCHAR(20) | 'weight', 'distance', etc. |

### `app_user`
| Field | Type | Notes |
|------|------|-------|
| id | SERIAL PK | |
| username | VARCHAR(50) | Unique |
| email | VARCHAR(255) | Unique |

### `activity_session`
| Field | Type | Notes |
|------|------|-------|
| id | SERIAL PK | |
| user_id | INT FK | |
| activity_type_id | INT FK | Required |
| activity_subtype_id | INT FK | Optional |
| started_at | TIMESTAMP | Required |
| ended_at | TIMESTAMP | |
| **duration_minutes** | INT | **Auto-calculated** |
| notes | TEXT | |

### `activity_metric` (EAV)
| Field | Type | Notes |
|------|------|-------|
| id | SERIAL PK | |
| session_id | INT FK | |
| metric_name | VARCHAR(50) | 'sets', 'weight', 'pages_read' |
| metric_value_numeric | DECIMAL | |
| metric_value_text | TEXT | |
| unit_id | INT FK | |

### `activity_type_metric_template`
| Field | Type | Notes |
|------|------|-------|
| activity_type_id | INT FK | |
| metric_name | VARCHAR(50) | |
| unit_id | INT FK | |
| is_required | BOOLEAN | |
| display_order | INT | |

---

## Relationships

```mermaid
graph TD
    A[activity_category] -->|1| B[activity_type]
    B -->|1| C[activity_subtype]
    B -->|1| T[activity_type_metric_template]
    U[unit] --> T
    User[app_user] -->|1| S[activity_session]
    S -->|1| B
    S -->|0..1| C
    S -->|1| M[activity_metric]
    U --> M