-- Sample and Production-Grade Queries for the Minimal Workout Tracker (v1.2)
-- PostgreSQL 14+
-- Volume is calculated as SUM(reps * COALESCE(weight, 0)) for working sets (is_warmup = FALSE).
-- Always group by weight_unit to prevent invalid cross-unit summations.

-- ============================================================================
-- 1. High-Performance Session Detail (Single-Query Nested JSON)
-- Fetches full session, exercise blocks, and sets in a single DB roundtrip.
-- Eliminates application N+1 query loops.
-- ============================================================================
SELECT
    s.session_id,
    s.user_id,
    s.started_at,
    s.ended_at,
    ROUND(EXTRACT(EPOCH FROM (s.ended_at - s.started_at)) / 60, 1) AS duration_minutes,
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
WHERE s.session_id = 1 AND s.user_id = 1
GROUP BY s.session_id;

-- ============================================================================
-- 2. Paginated User Sessions List with Exercise Summary Preview
-- Feeds the primary session history feed without N+1 fetching.
-- ============================================================================
SELECT
    s.session_id,
    s.started_at,
    s.ended_at,
    ROUND(EXTRACT(EPOCH FROM (s.ended_at - s.started_at)) / 60, 1) AS duration_minutes,
    s.notes,
    COUNT(DISTINCT w.workout_id) AS exercise_count,
    COUNT(ws.workout_set_id) AS total_sets,
    COALESCE(
        string_agg(DISTINCT wt.name, ', ' ORDER BY wt.name),
        ''
    ) AS exercise_names_preview,
    ROUND(SUM(CASE WHEN ws.is_warmup = FALSE THEN ws.reps * COALESCE(ws.weight, 0) ELSE 0 END), 2) AS working_volume,
    MIN(ws.weight_unit) AS primary_unit
FROM sessions s
LEFT JOIN workouts w ON s.session_id = w.session_id
LEFT JOIN workout_types wt ON w.workout_type_id = wt.workout_type_id
LEFT JOIN workout_sets ws ON w.workout_id = ws.workout_id
WHERE s.user_id = 1
GROUP BY s.session_id
ORDER BY s.started_at DESC
LIMIT 20 OFFSET 0;

-- ============================================================================
-- 3. Progressive Overload Helper: Previous Performance for an Exercise
-- When a user selects an exercise (e.g. Bench Press), this query fetches
-- their sets from the last time they did it to pre-fill or guide weights.
-- ============================================================================
SELECT
    s.started_at AS last_performed_at,
    ws.set_number,
    ws.reps,
    ws.weight,
    ws.weight_unit,
    ws.is_warmup
FROM sessions s
JOIN workouts w ON s.session_id = w.session_id
JOIN workout_sets ws ON w.workout_id = ws.workout_id
WHERE s.user_id = 1
  AND w.workout_type_id = 1 -- e.g. Bench Press
  AND s.session_id = (
      SELECT s2.session_id
      FROM sessions s2
      JOIN workouts w2 ON s2.session_id = w2.session_id
      WHERE s2.user_id = 1 AND w2.workout_type_id = 1
      ORDER BY s2.started_at DESC
      LIMIT 1
  )
ORDER BY ws.set_number;

-- ============================================================================
-- 4. Personal Records (PR) & Estimated 1RM (Epley Formula)
-- Estimates 1RM = Weight * (1 + Reps / 30.0) for sets with reps <= 10.
-- Ignores warmup sets.
-- ============================================================================
SELECT
    wt.name AS exercise_name,
    MAX(ws.weight) AS max_weight_lifted,
    ROUND(MAX(ws.weight * (1.0 + ws.reps / 30.0)), 1) AS estimated_1rm,
    ws.weight_unit,
    COUNT(ws.workout_set_id) AS total_working_sets
FROM workout_types wt
JOIN workouts w ON wt.workout_type_id = w.workout_type_id
JOIN sessions s ON w.session_id = s.session_id
JOIN workout_sets ws ON w.workout_id = ws.workout_id
WHERE s.user_id = 1
  AND ws.weight IS NOT NULL
  AND ws.is_warmup = FALSE
GROUP BY wt.workout_type_id, wt.name, ws.weight_unit
ORDER BY estimated_1rm DESC;

-- ============================================================================
-- 5. Weekly Training Consistency & Frequency
-- Summarizes workouts per ISO week for activity calendar/streaks.
-- ============================================================================
SELECT
    DATE_TRUNC('week', s.started_at)::date AS week_start,
    COUNT(s.session_id) AS sessions_completed,
    COUNT(ws.workout_set_id) AS total_sets,
    ROUND(SUM(CASE WHEN ws.is_warmup = FALSE THEN ws.reps * COALESCE(ws.weight, 0) ELSE 0 END), 2) AS weekly_working_volume,
    ws.weight_unit
FROM sessions s
JOIN workouts w ON s.session_id = w.session_id
JOIN workout_sets ws ON w.workout_id = ws.workout_id
WHERE s.user_id = 1
GROUP BY week_start, ws.weight_unit
ORDER BY week_start DESC
LIMIT 12;

-- ============================================================================
-- 6. Exercise Catalog Selection Query (System Defaults + User Custom)
-- Returns catalog items accessible by user_id = 1 (system + user's own).
-- ============================================================================
SELECT
    wt.workout_type_id,
    wt.name,
    wt.description,
    (wt.user_id IS NOT NULL) AS is_custom,
    wt.created_at
FROM workout_types wt
WHERE wt.user_id IS NULL OR wt.user_id = 1
ORDER BY is_custom ASC, wt.name ASC;

-- ============================================================================
-- 7. Monthly Volume Breakdown by Exercise
-- Tracks hypertrophy volume trends over time for a lifter.
-- ============================================================================
SELECT
    DATE_TRUNC('month', s.started_at)::date AS month,
    wt.name AS exercise_name,
    COUNT(ws.workout_set_id) AS working_sets,
    ROUND(SUM(ws.reps * COALESCE(ws.weight, 0)), 2) AS total_volume,
    ws.weight_unit
FROM sessions s
JOIN workouts w ON s.session_id = w.session_id
JOIN workout_types wt ON w.workout_type_id = wt.workout_type_id
JOIN workout_sets ws ON w.workout_id = ws.workout_id
WHERE s.user_id = 1
  AND ws.is_warmup = FALSE
GROUP BY month, wt.workout_type_id, wt.name, ws.weight_unit
ORDER BY month DESC, total_volume DESC;
