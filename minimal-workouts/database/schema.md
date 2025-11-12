# Database Schema Documentation

## Overview

The Weight Training Workout Tracker database is designed to store user information, workout sessions, and individual workout details. The schema is kept minimal with four main tables and basic audit information.

## Database Design Principles

- **Simplicity**: Limited to essential tables and fields
- **Audit Trail**: Each table includes `created_at` and `updated_at` timestamps
- **Referential Integrity**: Foreign key constraints ensure data consistency
- **PostgreSQL Specific**: Uses PostgreSQL data types and features

## Tables

### 1. users
Stores basic user account information.

**Columns:**
- `user_id` (BIGINT, PRIMARY KEY, AUTO_INCREMENT): Unique identifier for each user
- `name` (VARCHAR(255), NOT NULL): User's full name
- `email` (VARCHAR(255), NOT NULL, UNIQUE): User's email address
- `password_hash` (VARCHAR(255), NOT NULL): Hashed password for authentication
- `created_at` (TIMESTAMP, NOT NULL, DEFAULT CURRENT_TIMESTAMP): Account creation timestamp
- `updated_at` (TIMESTAMP, NOT NULL, DEFAULT CURRENT_TIMESTAMP): Last update timestamp

**Indexes:**
- PRIMARY KEY on `user_id`
- UNIQUE INDEX on `email`

### 2. workout_types
Master table for predefined workout types (e.g., Bench Press, Squat).

**Columns:**
- `workout_type_id` (BIGINT, PRIMARY KEY, AUTO_INCREMENT): Unique identifier for workout type
- `name` (VARCHAR(255), NOT NULL, UNIQUE): Name of the workout type
- `description` (TEXT): Optional description of the workout
- `created_at` (TIMESTAMP, NOT NULL, DEFAULT CURRENT_TIMESTAMP): Creation timestamp
- `updated_at` (TIMESTAMP, NOT NULL, DEFAULT CURRENT_TIMESTAMP): Last update timestamp

**Indexes:**
- PRIMARY KEY on `workout_type_id`
- UNIQUE INDEX on `name`

### 3. sessions
Represents a workout session performed by a user.

**Columns:**
- `session_id` (BIGINT, PRIMARY KEY, AUTO_INCREMENT): Unique identifier for session
- `user_id` (BIGINT, NOT NULL, FOREIGN KEY): Reference to the user who performed the session
- `session_date` (DATE, NOT NULL): Date when the session occurred
- `notes` (TEXT): Optional notes about the session
- `created_at` (TIMESTAMP, NOT NULL, DEFAULT CURRENT_TIMESTAMP): Creation timestamp
- `updated_at` (TIMESTAMP, NOT NULL, DEFAULT CURRENT_TIMESTAMP): Last update timestamp

**Indexes:**
- PRIMARY KEY on `session_id`
- FOREIGN KEY on `user_id` referencing `users.user_id`
- INDEX on `user_id`
- INDEX on `session_date`

### 4. workouts
Individual workout exercises within a session.

**Columns:**
- `workout_id` (BIGINT, PRIMARY KEY, AUTO_INCREMENT): Unique identifier for workout
- `session_id` (BIGINT, NOT NULL, FOREIGN KEY): Reference to the session this workout belongs to
- `workout_type_id` (BIGINT, NOT NULL, FOREIGN KEY): Reference to the workout type
- `sets` (INTEGER, NOT NULL): Number of sets performed
- `reps` (INTEGER, NOT NULL): Number of repetitions per set
- `weight` (DECIMAL(8,2), NOT NULL): Weight used for the exercise
- `weight_unit` (VARCHAR(10), NOT NULL): Unit of weight (e.g., 'kg', 'lbs')
- `created_at` (TIMESTAMP, NOT NULL, DEFAULT CURRENT_TIMESTAMP): Creation timestamp
- `updated_at` (TIMESTAMP, NOT NULL, DEFAULT CURRENT_TIMESTAMP): Last update timestamp

**Indexes:**
- PRIMARY KEY on `workout_id`
- FOREIGN KEY on `session_id` referencing `sessions.session_id`
- FOREIGN KEY on `workout_type_id` referencing `workout_types.workout_type_id`
- INDEX on `session_id`
- INDEX on `workout_type_id`

## Relationships

- **users** 1:N **sessions**: One user can have multiple workout sessions
- **sessions** 1:N **workouts**: One session can contain multiple workouts
- **workout_types** 1:N **workouts**: One workout type can be used in multiple workouts

## Constraints

- All foreign key relationships have CASCADE DELETE to maintain referential integrity
- Email addresses must be unique
- Workout type names must be unique
- Weight values are stored as DECIMAL(8,2) to allow for precise measurements
- Timestamps use PostgreSQL's CURRENT_TIMESTAMP for automatic updates

## Performance Considerations

- Indexes on frequently queried columns (user_id, session_date, workout_type_id)
- BIGINT primary keys for scalability
- Minimal table structure to reduce complexity and improve query performance