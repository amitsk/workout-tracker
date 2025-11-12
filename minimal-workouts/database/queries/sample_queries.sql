-- Sample Queries for Weight Training Workout Tracker
-- Includes aggregations and useful data analysis queries

-- 1. Total number of sessions per user
SELECT
    u.name,
    COUNT(s.session_id) as total_sessions
FROM users u
LEFT JOIN sessions s ON u.user_id = s.user_id
GROUP BY u.user_id, u.name
ORDER BY total_sessions DESC;

-- 2. Average weight lifted per workout type
SELECT
    wt.name as workout_type,
    ROUND(AVG(w.weight), 2) as avg_weight,
    w.weight_unit,
    COUNT(w.workout_id) as total_workouts
FROM workout_types wt
JOIN workouts w ON wt.workout_type_id = w.workout_type_id
GROUP BY wt.workout_type_id, wt.name, w.weight_unit
ORDER BY avg_weight DESC;

-- 3. Total volume (sets * reps * weight) per session
SELECT
    s.session_id,
    u.name as user_name,
    s.session_date,
    ROUND(SUM(w.sets * w.reps * w.weight), 2) as total_volume,
    w.weight_unit
FROM sessions s
JOIN users u ON s.user_id = u.user_id
JOIN workouts w ON s.session_id = w.session_id
GROUP BY s.session_id, u.name, s.session_date, w.weight_unit
ORDER BY s.session_date DESC;

-- 4. Monthly workout summary per user
SELECT
    u.name as user_name,
    DATE_TRUNC('month', s.session_date) as month,
    COUNT(DISTINCT s.session_id) as sessions_count,
    COUNT(w.workout_id) as total_workouts,
    ROUND(SUM(w.sets * w.reps * w.weight), 2) as monthly_volume,
    w.weight_unit
FROM users u
JOIN sessions s ON u.user_id = s.user_id
JOIN workouts w ON s.session_id = w.session_id
GROUP BY u.user_id, u.name, DATE_TRUNC('month', s.session_date), w.weight_unit
ORDER BY u.name, month DESC;

-- 5. Most popular workout types (by frequency)
SELECT
    wt.name as workout_type,
    COUNT(w.workout_id) as times_performed,
    COUNT(DISTINCT w.session_id) as sessions_used_in,
    ROUND(AVG(w.weight), 2) as avg_weight,
    w.weight_unit
FROM workout_types wt
JOIN workouts w ON wt.workout_type_id = w.workout_type_id
GROUP BY wt.workout_type_id, wt.name, w.weight_unit
ORDER BY times_performed DESC;

-- 6. User's workout history with details
SELECT
    u.name as user_name,
    s.session_date,
    wt.name as workout_type,
    w.sets,
    w.reps,
    w.weight,
    w.weight_unit,
    (w.sets * w.reps * w.weight) as volume
FROM users u
JOIN sessions s ON u.user_id = s.user_id
JOIN workouts w ON s.session_id = w.session_id
JOIN workout_types wt ON w.workout_type_id = wt.workout_type_id
WHERE u.user_id = 1 -- Change user_id to see different users
ORDER BY s.session_date DESC, wt.name;

-- 7. Weight progression for a specific workout type per user
SELECT
    u.name as user_name,
    wt.name as workout_type,
    s.session_date,
    MAX(w.weight) as max_weight,
    w.weight_unit
FROM users u
JOIN sessions s ON u.user_id = s.user_id
JOIN workouts w ON s.session_id = w.session_id
JOIN workout_types wt ON w.workout_type_id = wt.workout_type_id
WHERE wt.name = 'Bench Press' -- Change workout type as needed
GROUP BY u.user_id, u.name, wt.name, s.session_id, s.session_date, w.weight_unit
ORDER BY u.name, s.session_date;

-- 8. Sessions summary with workout count
SELECT
    s.session_id,
    u.name as user_name,
    s.session_date,
    s.notes,
    COUNT(w.workout_id) as workout_count,
    ROUND(SUM(w.sets * w.reps * w.weight), 2) as total_volume,
    w.weight_unit
FROM sessions s
JOIN users u ON s.user_id = u.user_id
LEFT JOIN workouts w ON s.session_id = w.session_id
GROUP BY s.session_id, u.name, s.session_date, s.notes, w.weight_unit
ORDER BY s.session_date DESC;

-- 9. Average sets and reps per workout type
SELECT
    wt.name as workout_type,
    ROUND(AVG(w.sets), 1) as avg_sets,
    ROUND(AVG(w.reps), 1) as avg_reps,
    COUNT(w.workout_id) as sample_size
FROM workout_types wt
JOIN workouts w ON wt.workout_type_id = w.workout_type_id
GROUP BY wt.workout_type_id, wt.name
HAVING COUNT(w.workout_id) >= 3 -- Only include workout types with at least 3 instances
ORDER BY avg_sets DESC;

-- 10. User activity summary
SELECT
    u.name as user_name,
    COUNT(DISTINCT s.session_id) as total_sessions,
    COUNT(w.workout_id) as total_workouts,
    ROUND(AVG(w.weight), 2) as avg_weight_per_workout,
    MAX(s.session_date) as last_session_date,
    MIN(s.session_date) as first_session_date,
    w.weight_unit
FROM users u
LEFT JOIN sessions s ON u.user_id = s.user_id
LEFT JOIN workouts w ON s.session_id = w.session_id
GROUP BY u.user_id, u.name, w.weight_unit
ORDER BY total_sessions DESC;