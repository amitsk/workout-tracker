# Activity Tracker – Comprehensive Database Schema

**Version**: 2.0
**Last Updated**: November 8, 2025
**Status**: Production Ready

---

## Overview

A comprehensive, extensible schema for tracking diverse activities including physical workouts (weight training, cardio, yoga, pilates), creative pursuits (painting, music), and wellness activities. The design supports:

- **Multi-platform**: Web and mobile with real-time sync
- **Flexible tracking**: EAV pattern for custom metrics + structured tables for common patterns
- **Goal management**: Comprehensive goal setting and progress tracking
- **Social features**: Following, sharing, and community engagement
- **Gamification**: Achievements, badges, and streak tracking
- **Body metrics**: Weight and body composition tracking
- **Workout programs**: Pre-built and custom training plans

---

## Architecture Principles

1. **Extensibility**: Add new activity types without schema changes
2. **Performance**: Optimized indexes and materialized views for analytics
3. **Data Integrity**: Foreign keys, constraints, and validation at database level
4. **Scalability**: Support for millions of sessions and users
5. **Privacy**: Row-level security and data isolation
6. **Auditability**: Soft deletes and timestamp tracking

---

## Core Tables

### 1. User Management

#### `app_user`
Primary user account and profile information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Unique user identifier |
| username | VARCHAR(50) | UNIQUE, NOT NULL | Display name |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Email address |
| password_hash | VARCHAR(255) | | Hashed password (bcrypt/Argon2) |
| first_name | VARCHAR(100) | | User's first name |
| last_name | VARCHAR(100) | | User's last name |
| avatar_url | VARCHAR(500) | | Profile picture URL |
| timezone | VARCHAR(50) | DEFAULT 'UTC' | User's timezone |
| measurement_preference | VARCHAR(10) | DEFAULT 'metric' | 'metric' or 'imperial' |
| weight_unit_id | INT | FK → unit | Preferred weight unit |
| distance_unit_id | INT | FK → unit | Preferred distance unit |
| date_format | VARCHAR(20) | DEFAULT 'YYYY-MM-DD' | Date display format |
| language | VARCHAR(10) | DEFAULT 'en' | UI language code |
| is_active | BOOLEAN | DEFAULT TRUE | Account active status |
| email_verified | BOOLEAN | DEFAULT FALSE | Email verification status |
| last_login_at | TIMESTAMP | | Last login timestamp |
| created_at | TIMESTAMP | DEFAULT NOW() | Account creation |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last profile update |
| deleted_at | TIMESTAMP | | Soft delete timestamp |

**Constraints**:
```sql
CHECK (measurement_preference IN ('metric', 'imperial'))
CHECK (LENGTH(username) >= 3)
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
```

**Indexes**:
```sql
CREATE INDEX idx_user_email ON app_user(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_active ON app_user(is_active) WHERE is_active = TRUE;
```

---

### 2. Activity Hierarchy

#### `activity_category`
Top-level activity categories (Physical, Creative, Wellness, Cognitive).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Category identifier |
| name | VARCHAR(50) | UNIQUE, NOT NULL | Category name |
| description | TEXT | | Category description |
| icon_name | VARCHAR(50) | | Icon reference |
| display_order | INT | DEFAULT 0 | Sort order in UI |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Examples**: Physical, Creative, Wellness, Cognitive, Social

---

#### `activity_type`
Specific activity types within categories.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Type identifier |
| name | VARCHAR(100) | UNIQUE, NOT NULL | Type name |
| category_id | INT | FK → activity_category | Parent category |
| is_physical | BOOLEAN | DEFAULT TRUE | Physical activity flag |
| has_duration | BOOLEAN | DEFAULT TRUE | Duration tracking enabled |
| has_intensity | BOOLEAN | DEFAULT FALSE | Intensity tracking enabled |
| description | TEXT | | Type description |
| icon_url | VARCHAR(255) | | Icon/image URL |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Examples**:
- Physical → Weight Training, Running, Yoga, Pilates, Swimming
- Creative → Painting, Music, Dance, Writing
- Wellness → Meditation, Massage, Breathing

**Indexes**:
```sql
CREATE INDEX idx_activity_type_category ON activity_type(category_id);
```

---

#### `activity_subtype`
Specific exercises or sub-activities within a type.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Subtype identifier |
| activity_type_id | INT | FK → activity_type, NOT NULL | Parent type |
| name | VARCHAR(100) | NOT NULL | Subtype/exercise name |
| description | TEXT | | Exercise description |
| default_sets | INT | | Default set count |
| default_reps | INT | | Default rep count |
| default_weight | DECIMAL(6,2) | | Default weight |
| default_weight_unit | VARCHAR(10) | DEFAULT 'kg' | Default unit |
| muscle_groups | TEXT[] | | Target muscle groups |
| difficulty_level | VARCHAR(20) | | 'beginner', 'intermediate', 'advanced' |
| equipment_needed | TEXT[] | | Required equipment |
| instructions | TEXT | | Exercise instructions |
| video_url | VARCHAR(500) | | Tutorial video URL |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Unique Constraint**: `(activity_type_id, name)`

**Examples**:
- Weight Training → Squat, Bench Press, Deadlift, Overhead Press
- Yoga → Downward Dog, Warrior I, Tree Pose
- Music → Guitar Practice, Piano Scales, Vocal Exercises

**Indexes**:
```sql
CREATE INDEX idx_subtype_type ON activity_subtype(activity_type_id, name);
CREATE INDEX idx_subtype_search ON activity_subtype USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));
```

---

### 3. Units of Measurement

#### `unit`
All measurement units used throughout the system.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Unit identifier |
| name | VARCHAR(20) | UNIQUE, NOT NULL | Unit full name |
| symbol | VARCHAR(10) | | Unit abbreviation |
| type | VARCHAR(20) | | Unit category |
| conversion_factor | DECIMAL(12,6) | | Conversion to base unit |
| is_base_unit | BOOLEAN | DEFAULT FALSE | Base unit flag |

**Types**: weight, distance, time, count, speed, energy, percentage

**Examples**:
```
Weight: kilograms (kg), pounds (lbs), grams (g)
Distance: kilometers (km), miles (mi), meters (m)
Time: seconds (s), minutes (min), hours (h)
Count: repetitions (reps), sets, count
Speed: km/h, mph, m/s
Energy: calories (cal), kilojoules (kJ)
```

**Indexes**:
```sql
CREATE INDEX idx_unit_type ON unit(type);
```

---

### 4. Activity Sessions

#### `activity_session`
Individual activity session instances.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Session identifier |
| user_id | INT | FK → app_user, NOT NULL | Session owner |
| activity_type_id | INT | FK → activity_type, NOT NULL | Activity type |
| activity_subtype_id | INT | FK → activity_subtype | Optional subtype |
| session_name | VARCHAR(200) | | Custom session name |
| started_at | TIMESTAMP | NOT NULL | Session start time |
| ended_at | TIMESTAMP | | Session end time |
| duration_minutes | INT | GENERATED ALWAYS | Auto-calculated duration |
| location | VARCHAR(100) | | Location/gym name |
| weather | VARCHAR(100) | | Weather conditions |
| mood_before | VARCHAR(50) | | Pre-session mood |
| mood_after | VARCHAR(50) | | Post-session mood |
| energy_level | INT | CHECK (1-10) | Energy level (1-10) |
| rating | INT | CHECK (1-10) | Session rating (1-10) |
| perceived_exertion | INT | CHECK (1-10) | RPE (1-10) |
| injuries_noted | TEXT | | Injuries or discomfort |
| notes | TEXT | | Session notes |
| total_volume | DECIMAL(12,2) | | Total volume (sets×reps×weight) |
| estimated_calories | DECIMAL(8,2) | | Estimated calories burned |
| is_personal_record | BOOLEAN | DEFAULT FALSE | PR achieved flag |
| is_template | BOOLEAN | DEFAULT FALSE | Template session flag |
| template_name | VARCHAR(200) | | Template name |
| parent_session_id | INT | FK → activity_session | Source template |
| search_vector | TSVECTOR | | Full-text search vector |
| created_at | TIMESTAMP | DEFAULT NOW() | Record creation |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |
| deleted_at | TIMESTAMP | | Soft delete timestamp |

**Generated Column**:
```sql
duration_minutes INT GENERATED ALWAYS AS (
    CASE WHEN ended_at IS NOT NULL
    THEN EXTRACT(EPOCH FROM (ended_at - started_at))/60
    ELSE NULL END
) STORED
```

**Constraints**:
```sql
CHECK (ended_at IS NULL OR ended_at >= started_at)
CHECK (rating IS NULL OR (rating >= 1 AND rating <= 10))
CHECK (energy_level IS NULL OR (energy_level >= 1 AND energy_level <= 10))
CHECK (perceived_exertion IS NULL OR (perceived_exertion >= 1 AND perceived_exertion <= 10))
```

**Indexes**:
```sql
CREATE INDEX idx_session_user_date ON activity_session(user_id, started_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_session_type_date ON activity_session(activity_type_id, started_at DESC);
CREATE INDEX idx_session_subtype ON activity_session(user_id, activity_subtype_id, started_at DESC) WHERE activity_subtype_id IS NOT NULL;
CREATE INDEX idx_session_templates ON activity_session(user_id, is_template) WHERE is_template = TRUE;
CREATE INDEX idx_session_search ON activity_session USING gin(search_vector);
CREATE INDEX idx_session_date_trunc ON activity_session(user_id, DATE_TRUNC('day', started_at));
```

---

### 5. Exercise & Set Tracking (Strength Training)

#### `activity_exercise`
Individual exercises within a session (primarily for strength training).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Exercise identifier |
| session_id | INT | FK → activity_session, NOT NULL | Parent session |
| activity_subtype_id | INT | FK → activity_subtype | Exercise type |
| exercise_order | INT | NOT NULL | Order in session |
| superset_group | INT | | Group for supersets/circuits |
| notes | TEXT | | Exercise-specific notes |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Indexes**:
```sql
CREATE INDEX idx_exercise_session ON activity_exercise(session_id, exercise_order);
CREATE INDEX idx_exercise_subtype ON activity_exercise(activity_subtype_id);
```

---

#### `exercise_set`
Individual sets within an exercise.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Set identifier |
| exercise_id | INT | FK → activity_exercise, NOT NULL | Parent exercise |
| set_number | INT | NOT NULL | Set number (1, 2, 3...) |
| reps | INT | | Repetitions completed |
| weight | DECIMAL(8,2) | | Weight used |
| weight_unit_id | INT | FK → unit | Weight unit |
| rest_seconds | INT | | Rest before next set |
| rpe | INT | CHECK (1-10) | Rate of Perceived Exertion |
| tempo | VARCHAR(20) | | Tempo notation (e.g., "3-1-1-0") |
| is_warmup | BOOLEAN | DEFAULT FALSE | Warmup set flag |
| is_failure | BOOLEAN | DEFAULT FALSE | Reached failure |
| is_drop_set | BOOLEAN | DEFAULT FALSE | Drop set flag |
| form_video_url | VARCHAR(500) | | Form check video URL |
| notes | TEXT | | Set notes |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Unique Constraint**: `(exercise_id, set_number)`

**Constraints**:
```sql
CHECK (rpe IS NULL OR (rpe >= 1 AND rpe <= 10))
CHECK (reps IS NULL OR reps > 0)
CHECK (weight IS NULL OR weight >= 0)
```

**Indexes**:
```sql
CREATE INDEX idx_set_exercise ON exercise_set(exercise_id, set_number);
CREATE INDEX idx_set_weight ON exercise_set(weight DESC) WHERE weight IS NOT NULL;
CREATE INDEX idx_set_reps ON exercise_set(reps DESC) WHERE reps IS NOT NULL;
```

---

### 6. Flexible Metrics (EAV Pattern)

#### `activity_metric`
Flexible key-value metrics for non-strength activities.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Metric identifier |
| session_id | INT | FK → activity_session, NOT NULL | Parent session |
| metric_name | VARCHAR(50) | NOT NULL | Metric name |
| metric_value_numeric | DECIMAL(10,3) | | Numeric value |
| metric_value_text | TEXT | | Text value |
| unit_id | INT | FK → unit | Measurement unit |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Constraints**:
```sql
CHECK (
    (metric_value_numeric IS NOT NULL AND metric_value_text IS NULL) OR
    (metric_value_numeric IS NULL AND metric_value_text IS NOT NULL)
)
CHECK (metric_value_numeric IS NULL OR metric_value_numeric >= 0)
```

**Common Metrics**:
- Cardio: distance, pace, heart_rate, elevation_gain
- Yoga: poses_held, balance_time, flexibility_score
- Creative: pages_created, brush_strokes, notes_played, words_written

**Indexes**:
```sql
CREATE INDEX idx_metric_session ON activity_metric(session_id, metric_name);
CREATE INDEX idx_metric_name_value ON activity_metric(metric_name, metric_value_numeric DESC NULLS LAST);
```

---

#### `activity_type_metric_template`
Default metrics for each activity type (guides UI).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Template identifier |
| activity_type_id | INT | FK → activity_type, NOT NULL | Activity type |
| metric_name | VARCHAR(50) | NOT NULL | Metric name |
| unit_id | INT | FK → unit | Default unit |
| is_required | BOOLEAN | DEFAULT FALSE | Required field flag |
| display_order | INT | DEFAULT 0 | UI display order |
| input_type | VARCHAR(20) | | 'number', 'text', 'duration' |
| validation_rule | TEXT | | Validation regex/rule |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Unique Constraint**: `(activity_type_id, metric_name)`

**Indexes**:
```sql
CREATE INDEX idx_template_activity ON activity_type_metric_template(activity_type_id, display_order);
```

---

### 7. Media Attachments

#### `session_media`
Photos, videos, and other media attached to sessions or exercises.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Media identifier |
| session_id | INT | FK → activity_session | Parent session |
| exercise_id | INT | FK → activity_exercise | Parent exercise |
| media_type | VARCHAR(20) | NOT NULL | 'image', 'video', 'audio' |
| media_url | VARCHAR(500) | NOT NULL | Media storage URL |
| thumbnail_url | VARCHAR(500) | | Thumbnail URL |
| file_size_bytes | BIGINT | | File size |
| duration_seconds | INT | | Duration for video/audio |
| caption | TEXT | | Media caption |
| tags | TEXT[] | | Searchable tags |
| is_progress_photo | BOOLEAN | DEFAULT FALSE | Progress photo flag |
| is_form_check | BOOLEAN | DEFAULT FALSE | Form check video flag |
| created_at | TIMESTAMP | DEFAULT NOW() | Upload timestamp |

**Constraints**:
```sql
CHECK (media_type IN ('image', 'video', 'audio'))
CHECK (
    (session_id IS NOT NULL AND exercise_id IS NULL) OR
    (session_id IS NULL AND exercise_id IS NOT NULL)
)
```

**Indexes**:
```sql
CREATE INDEX idx_media_session ON session_media(session_id, created_at DESC);
CREATE INDEX idx_media_exercise ON session_media(exercise_id);
CREATE INDEX idx_progress_photos ON session_media(session_id, created_at DESC) WHERE is_progress_photo = TRUE;
CREATE INDEX idx_media_tags ON session_media USING gin(tags);
```

---

### 8. Goal Management

#### `goal_type`
Types of goals users can set.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Goal type identifier |
| name | VARCHAR(50) | UNIQUE, NOT NULL | Type name |
| description | TEXT | | Type description |
| icon_name | VARCHAR(50) | | Icon reference |

**Examples**: frequency, performance, habit, time_based, body_composition

---

#### `user_goal`
User-defined goals.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Goal identifier |
| user_id | INT | FK → app_user, NOT NULL | Goal owner |
| goal_type_id | INT | FK → goal_type, NOT NULL | Goal category |
| activity_type_id | INT | FK → activity_type | Target activity |
| activity_subtype_id | INT | FK → activity_subtype | Target exercise |
| title | VARCHAR(200) | NOT NULL | Goal title |
| description | TEXT | | Goal description |
| target_value | DECIMAL(10,2) | | Target value |
| target_unit_id | INT | FK → unit | Target unit |
| current_value | DECIMAL(10,2) | | Current progress |
| start_date | DATE | NOT NULL | Start date |
| target_date | DATE | | Target completion date |
| frequency_per_week | INT | | For frequency goals |
| is_completed | BOOLEAN | DEFAULT FALSE | Completion flag |
| completed_at | TIMESTAMP | | Completion timestamp |
| is_active | BOOLEAN | DEFAULT TRUE | Active flag |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |

**Indexes**:
```sql
CREATE INDEX idx_user_goals ON user_goal(user_id, is_active, target_date);
CREATE INDEX idx_goal_type ON user_goal(goal_type_id, is_active);
```

---

#### `goal_milestone`
Intermediate milestones within a goal.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Milestone identifier |
| goal_id | INT | FK → user_goal, NOT NULL | Parent goal |
| title | VARCHAR(200) | NOT NULL | Milestone title |
| target_value | DECIMAL(10,2) | | Milestone target |
| achieved_at | TIMESTAMP | | Achievement timestamp |
| is_achieved | BOOLEAN | DEFAULT FALSE | Achievement flag |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Indexes**:
```sql
CREATE INDEX idx_milestone_goal ON goal_milestone(goal_id, is_achieved);
```

---

### 9. Personal Records

#### `personal_record`
Tracked personal records for exercises.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | PR identifier |
| user_id | INT | FK → app_user, NOT NULL | Record holder |
| activity_subtype_id | INT | FK → activity_subtype, NOT NULL | Exercise |
| record_type | VARCHAR(30) | NOT NULL | '1rm', 'max_weight', 'max_reps', 'max_volume' |
| record_value | DECIMAL(10,2) | NOT NULL | Record value |
| unit_id | INT | FK → unit | Measurement unit |
| session_id | INT | FK → activity_session, NOT NULL | Session achieved |
| exercise_id | INT | FK → activity_exercise | Specific exercise |
| previous_record_value | DECIMAL(10,2) | | Previous record |
| achieved_at | TIMESTAMP | NOT NULL DEFAULT NOW() | Achievement date |
| notes | TEXT | | PR notes |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Unique Constraint**: `(user_id, activity_subtype_id, record_type)`

**Indexes**:
```sql
CREATE INDEX idx_user_prs ON personal_record(user_id, activity_subtype_id, record_type);
CREATE INDEX idx_pr_achieved ON personal_record(user_id, achieved_at DESC);
CREATE INDEX idx_pr_subtype ON personal_record(activity_subtype_id, record_value DESC);
```

---

### 10. Body Metrics

#### `body_metric_type`
Types of body measurements tracked.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Type identifier |
| name | VARCHAR(50) | UNIQUE, NOT NULL | Metric name |
| category | VARCHAR(30) | | 'weight', 'composition', 'measurement' |
| default_unit_id | INT | FK → unit | Default unit |
| description | TEXT | | Metric description |

**Examples**: weight, body_fat_percentage, chest, waist, biceps, thighs

---

#### `user_body_metric`
User body measurements over time.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Measurement identifier |
| user_id | INT | FK → app_user, NOT NULL | User |
| metric_type_id | INT | FK → body_metric_type, NOT NULL | Metric type |
| value | DECIMAL(8,2) | NOT NULL | Measurement value |
| unit_id | INT | FK → unit, NOT NULL | Measurement unit |
| measured_at | TIMESTAMP | NOT NULL DEFAULT NOW() | Measurement time |
| notes | TEXT | | Measurement notes |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Indexes**:
```sql
CREATE INDEX idx_body_metrics ON user_body_metric(user_id, metric_type_id, measured_at DESC);
```

---

### 11. Workout Programs

#### `workout_program`
Pre-built or custom workout programs.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Program identifier |
| creator_id | INT | FK → app_user | Creator (NULL if system) |
| name | VARCHAR(200) | NOT NULL | Program name |
| description | TEXT | | Program description |
| difficulty_level | VARCHAR(20) | | 'beginner', 'intermediate', 'advanced' |
| duration_weeks | INT | | Program duration |
| sessions_per_week | INT | | Weekly frequency |
| category_id | INT | FK → activity_category | Program category |
| is_public | BOOLEAN | DEFAULT FALSE | Public visibility |
| is_official | BOOLEAN | DEFAULT FALSE | Official program flag |
| tags | TEXT[] | | Searchable tags |
| thumbnail_url | VARCHAR(500) | | Program thumbnail |
| search_vector | TSVECTOR | | Full-text search |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |
| deleted_at | TIMESTAMP | | Soft delete timestamp |

**Constraints**:
```sql
CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced'))
```

**Indexes**:
```sql
CREATE INDEX idx_programs_public ON workout_program(is_public, is_official) WHERE deleted_at IS NULL;
CREATE INDEX idx_program_creator ON workout_program(creator_id);
CREATE INDEX idx_program_search ON workout_program USING gin(search_vector);
```

---

#### `program_session_template`
Session templates within a program.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Template identifier |
| program_id | INT | FK → workout_program, NOT NULL | Parent program |
| week_number | INT | NOT NULL | Week in program |
| day_number | INT | NOT NULL | Day of week |
| session_name | VARCHAR(200) | | Session name |
| description | TEXT | | Session description |
| activity_type_id | INT | FK → activity_type, NOT NULL | Activity type |
| estimated_duration_minutes | INT | | Estimated duration |
| display_order | INT | DEFAULT 0 | Display order |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Indexes**:
```sql
CREATE INDEX idx_program_sessions ON program_session_template(program_id, week_number, day_number);
```

---

#### `program_exercise_template`
Exercise templates within a program session.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Template identifier |
| session_template_id | INT | FK → program_session_template, NOT NULL | Parent session |
| activity_subtype_id | INT | FK → activity_subtype | Exercise |
| exercise_order | INT | NOT NULL | Order in session |
| target_sets | INT | | Target sets |
| target_reps | INT | | Target reps |
| target_weight_pct | DECIMAL(5,2) | | % of 1RM |
| rest_seconds | INT | | Rest between sets |
| notes | TEXT | | Exercise notes |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Indexes**:
```sql
CREATE INDEX idx_template_exercises ON program_exercise_template(session_template_id, exercise_order);
```

---

#### `user_program_enrollment`
User enrollment in workout programs.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Enrollment identifier |
| user_id | INT | FK → app_user, NOT NULL | Enrolled user |
| program_id | INT | FK → workout_program, NOT NULL | Enrolled program |
| start_date | DATE | NOT NULL | Start date |
| current_week | INT | DEFAULT 1 | Current week |
| current_day | INT | DEFAULT 1 | Current day |
| is_active | BOOLEAN | DEFAULT TRUE | Active enrollment |
| completed_at | TIMESTAMP | | Completion timestamp |
| created_at | TIMESTAMP | DEFAULT NOW() | Enrollment timestamp |

**Indexes**:
```sql
CREATE INDEX idx_user_enrollments ON user_program_enrollment(user_id, is_active);
CREATE INDEX idx_program_enrollments ON user_program_enrollment(program_id, is_active);
```

---

### 12. Gamification

#### `achievement_type`
Types of achievements users can earn.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Achievement identifier |
| name | VARCHAR(100) | UNIQUE, NOT NULL | Achievement name |
| description | TEXT | | Achievement description |
| badge_icon_url | VARCHAR(500) | | Badge image URL |
| category | VARCHAR(50) | | 'streak', 'milestone', 'volume' |
| criteria_json | JSONB | | Criteria definition |
| points | INT | DEFAULT 0 | Points awarded |
| rarity | VARCHAR(20) | | 'common', 'rare', 'epic', 'legendary' |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Constraints**:
```sql
CHECK (rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary'))
```

---

#### `user_achievement`
Achievements earned by users.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Award identifier |
| user_id | INT | FK → app_user, NOT NULL | User who earned |
| achievement_type_id | INT | FK → achievement_type, NOT NULL | Achievement earned |
| earned_at | TIMESTAMP | NOT NULL DEFAULT NOW() | Earned timestamp |
| related_session_id | INT | FK → activity_session | Related session |
| progress_value | DECIMAL(10,2) | | Value at earning |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |

**Unique Constraint**: `(user_id, achievement_type_id)`

**Indexes**:
```sql
CREATE INDEX idx_user_achievements ON user_achievement(user_id, earned_at DESC);
```

---

#### `user_streak`
Activity streak tracking.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Streak identifier |
| user_id | INT | FK → app_user, NOT NULL | User |
| activity_type_id | INT | FK → activity_type | Specific activity (NULL = overall) |
| current_streak_days | INT | DEFAULT 0 | Current streak |
| longest_streak_days | INT | DEFAULT 0 | Longest ever streak |
| last_activity_date | DATE | | Last activity date |
| created_at | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last update |

**Unique Constraint**: `(user_id, activity_type_id)`

**Indexes**:
```sql
CREATE INDEX idx_user_streaks ON user_streak(user_id, current_streak_days DESC);
CREATE INDEX idx_streak_activity ON user_streak(activity_type_id);
```

---

### 13. Social Features

#### `user_relationship`
User following relationships.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Relationship identifier |
| follower_id | INT | FK → app_user, NOT NULL | Follower user |
| following_id | INT | FK → app_user, NOT NULL | Followed user |
| created_at | TIMESTAMP | DEFAULT NOW() | Follow timestamp |

**Unique Constraint**: `(follower_id, following_id)`

**Constraints**:
```sql
CHECK (follower_id != following_id)
```

**Indexes**:
```sql
CREATE INDEX idx_followers ON user_relationship(following_id);
CREATE INDEX idx_following ON user_relationship(follower_id);
```

---

#### `session_share`
Shared sessions for social feed.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Share identifier |
| session_id | INT | FK → activity_session, NOT NULL | Shared session |
| shared_by_user_id | INT | FK → app_user, NOT NULL | User sharing |
| visibility | VARCHAR(20) | DEFAULT 'friends' | 'public', 'friends', 'private' |
| share_message | TEXT | | Optional message |
| created_at | TIMESTAMP | DEFAULT NOW() | Share timestamp |

**Constraints**:
```sql
CHECK (visibility IN ('public', 'friends', 'private'))
```

**Indexes**:
```sql
CREATE INDEX idx_session_shares ON session_share(shared_by_user_id, visibility, created_at DESC);
CREATE INDEX idx_shared_session ON session_share(session_id);
```

---

#### `session_comment`
Comments on shared sessions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Comment identifier |
| session_id | INT | FK → activity_session, NOT NULL | Commented session |
| user_id | INT | FK → app_user, NOT NULL | Commenter |
| comment_text | TEXT | NOT NULL | Comment content |
| created_at | TIMESTAMP | DEFAULT NOW() | Comment timestamp |
| updated_at | TIMESTAMP | DEFAULT NOW() | Last edit |
| deleted_at | TIMESTAMP | | Soft delete timestamp |

**Indexes**:
```sql
CREATE INDEX idx_session_comments ON session_comment(session_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_comments ON session_comment(user_id, created_at DESC);
```

---

#### `session_like`
Likes on shared sessions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PK | Like identifier |
| session_id | INT | FK → activity_session, NOT NULL | Liked session |
| user_id | INT | FK → app_user, NOT NULL | User who liked |
| created_at | TIMESTAMP | DEFAULT NOW() | Like timestamp |

**Unique Constraint**: `(session_id, user_id)`

**Indexes**:
```sql
CREATE INDEX idx_session_likes ON session_like(session_id);
CREATE INDEX idx_user_likes ON session_like(user_id, created_at DESC);
```

---

## Materialized Views

### `user_statistics`
Pre-calculated user statistics for dashboard.

```sql
CREATE MATERIALIZED VIEW user_statistics AS
SELECT
    user_id,
    COUNT(*) as total_sessions,
    COUNT(DISTINCT DATE(started_at)) as total_days_active,
    MAX(started_at) as last_activity,
    SUM(duration_minutes) as total_minutes,
    AVG(rating) as avg_session_rating,
    SUM(estimated_calories) as total_calories,
    COUNT(*) FILTER (WHERE is_personal_record = TRUE) as total_prs
FROM activity_session
WHERE deleted_at IS NULL
GROUP BY user_id;

CREATE UNIQUE INDEX idx_user_stats_user ON user_statistics(user_id);
```

---

## Performance Optimization

### Key Indexes Summary
- **User lookups**: email, username, active status
- **Session queries**: user_id + date, type + date, subtype + date
- **Analytics**: Date truncation, metric name/value
- **Search**: Full-text search on sessions, exercises, programs
- **Social**: Relationships, shares, comments by user and date

### Query Performance Targets
- Session list (100 rows): < 50ms
- Dashboard aggregations: < 200ms
- PR calculations: < 100ms
- Full-text search: < 150ms
- Goal progress: < 100ms

---

## Security

### Row-Level Security (RLS)

```sql
-- Enable RLS on sensitive tables
ALTER TABLE activity_session ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_goal ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_body_metric ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY user_data_isolation ON activity_session
    FOR ALL
    USING (user_id = current_setting('app.current_user_id')::INT);
```

### Data Protection
- Passwords: bcrypt/Argon2 hashing
- Sensitive fields: Consider encryption for PII
- Soft deletes: deleted_at timestamp instead of hard deletes
- Audit logs: created_at, updated_at on all tables

---

## Extensibility Examples

### Adding a New Activity Type (Chess)

```sql
-- 1. Add category if needed
INSERT INTO activity_category (name, description)
VALUES ('Cognitive', 'Mental and cognitive activities');

-- 2. Add activity type
INSERT INTO activity_type (name, category_id, is_physical, has_duration)
VALUES ('Chess', (SELECT id FROM activity_category WHERE name='Cognitive'), FALSE, TRUE);

-- 3. Define metrics
INSERT INTO activity_type_metric_template
    (activity_type_id, metric_name, unit_id, is_required, display_order)
VALUES
    ((SELECT id FROM activity_type WHERE name='Chess'),
     'duration_minutes',
     (SELECT id FROM unit WHERE name='minutes'),
     TRUE, 1),
    ((SELECT id FROM activity_type WHERE name='Chess'),
     'moves',
     (SELECT id FROM unit WHERE name='count'),
     FALSE, 2);
```

### Adding a New Body Metric (Chest Measurement)

```sql
INSERT INTO body_metric_type (name, category, default_unit_id)
VALUES ('chest', 'measurement', (SELECT id FROM unit WHERE name='centimeters'));
```

---

## Migration Notes

### From Version 1.0
1. Add new columns to app_user (profile fields)
2. Create new tables (exercise_set, goals, body_metrics, programs, gamification, social)
3. Migrate existing strength data from activity_metric to exercise_set
4. Add missing indexes
5. Create materialized views
6. Enable RLS policies

### Data Integrity
- All foreign keys use appropriate ON DELETE actions
- CHECK constraints validate data at insert/update
- Unique constraints prevent duplicates
- Generated columns auto-calculate values

---

## Testing Recommendations

### Unit Tests
- Foreign key constraints
- CHECK constraints
- Cascade deletes
- Generated column calculations

### Performance Tests
- Load test with 1M+ sessions
- Index effectiveness
- Materialized view refresh times
- Concurrent write conflicts

### Integration Tests
- Full session creation flow
- Goal progress calculation
- PR detection and updates
- Social feed generation

---

## Backup & Recovery

### Backup Strategy
- Full daily backups
- Point-in-time recovery enabled
- Transaction log backups every 15 minutes
- Backup retention: 30 days

### Disaster Recovery
- RTO (Recovery Time Objective): 1 hour
- RPO (Recovery Point Objective): 15 minutes
- Geo-replicated backups
- Automated failover configuration

---

## Future Enhancements

### Phase 4 (Future)
1. **Partitioning**: Partition activity_session by date for extreme scale
2. **Time-series database**: Consider TimescaleDB for metrics
3. **GraphQL integration**: Add Hasura or PostGraphile
4. **AI/ML features**: Exercise form analysis, injury prediction
5. **Blockchain**: NFT badges for achievements
6. **Wearable integration**: Direct sync from devices

---

## Appendix

### Naming Conventions
- Tables: lowercase, underscores, plural for junction tables
- Columns: lowercase, underscores, descriptive names
- Indexes: `idx_<table>_<columns>`
- Foreign keys: `fk_<table>_<reference>`
- Constraints: `chk_<table>_<condition>`

### References
- PostgreSQL 14+ documentation
- Performance tuning guide
- Security best practices (OWASP)
- GDPR compliance requirements

---

**Document Status**: ✅ Complete
**Next Review**: February 2026
**Maintained By**: Database Architecture Team
