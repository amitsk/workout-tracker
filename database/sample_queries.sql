-- ============================================================================
-- Activity Tracker Sample Queries
-- Version: 2.0
-- Comprehensive query examples for common use cases
-- ============================================================================

-- ============================================================================
-- USER & PROFILE QUERIES
-- ============================================================================

-- 1. Get user profile with preferences
SELECT
    u.id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    u.timezone,
    u.measurement_preference,
    wu.symbol as preferred_weight_unit,
    du.symbol as preferred_distance_unit,
    u.last_login_at,
    u.created_at
FROM app_user u
LEFT JOIN unit wu ON u.weight_unit_id = wu.id
LEFT JOIN unit du ON u.distance_unit_id = du.id
WHERE u.username = 'john_lifter'
AND u.deleted_at IS NULL;

-- 2. Get user's follower count and following count
SELECT
    u.username,
    (SELECT COUNT(*) FROM user_relationship WHERE following_id = u.id) as followers,
    (SELECT COUNT(*) FROM user_relationship WHERE follower_id = u.id) as following
FROM app_user u
WHERE u.id = 1;

-- 3. Find active users who joined in the last 30 days
SELECT
    username,
    email,
    first_name,
    last_name,
    created_at
FROM app_user
WHERE is_active = TRUE
AND email_verified = TRUE
AND created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC;

-- ============================================================================
-- SESSION QUERIES
-- ============================================================================

-- 4. Get user's recent activity sessions with details
SELECT
    s.id,
    s.session_name,
    at.name as activity_type,
    ast.name as activity_subtype,
    s.started_at,
    s.ended_at,
    s.duration_minutes,
    s.location,
    s.rating,
    s.perceived_exertion,
    s.estimated_calories,
    s.notes
FROM activity_session s
JOIN activity_type at ON s.activity_type_id = at.id
LEFT JOIN activity_subtype ast ON s.activity_subtype_id = ast.id
WHERE s.user_id = 1
AND s.deleted_at IS NULL
ORDER BY s.started_at DESC
LIMIT 10;

-- 5. Get session count by activity type for a user
SELECT
    at.name as activity_type,
    COUNT(*) as session_count,
    SUM(s.duration_minutes) as total_minutes,
    ROUND(AVG(s.rating), 2) as avg_rating,
    SUM(s.estimated_calories) as total_calories
FROM activity_session s
JOIN activity_type at ON s.activity_type_id = at.id
WHERE s.user_id = 2
AND s.deleted_at IS NULL
GROUP BY at.name
ORDER BY session_count DESC;

-- 6. Get sessions in a specific date range
SELECT
    s.session_name,
    at.name as activity_type,
    s.started_at,
    s.duration_minutes,
    s.rating
FROM activity_session s
JOIN activity_type at ON s.activity_type_id = at.id
WHERE s.user_id = 1
AND s.started_at >= '2025-01-01'
AND s.started_at < '2025-02-01'
AND s.deleted_at IS NULL
ORDER BY s.started_at;

-- 7. Get sessions with personal records
SELECT
    s.id,
    s.session_name,
    s.started_at,
    at.name as activity_type,
    pr.record_type,
    pr.record_value,
    u.symbol as unit,
    pr.previous_record_value,
    pr.notes as pr_notes
FROM activity_session s
JOIN activity_type at ON s.activity_type_id = at.id
JOIN personal_record pr ON s.id = pr.session_id
LEFT JOIN unit u ON pr.unit_id = u.id
WHERE s.user_id = 1
AND s.is_personal_record = TRUE
ORDER BY pr.achieved_at DESC;

-- ============================================================================
-- STRENGTH TRAINING QUERIES
-- ============================================================================

-- 8. Get detailed workout with exercises and sets
SELECT
    s.session_name,
    s.started_at,
    ast.name as exercise_name,
    ae.exercise_order,
    es.set_number,
    es.reps,
    es.weight,
    u.symbol as unit,
    es.rpe,
    es.rest_seconds,
    es.is_warmup,
    es.is_failure
FROM activity_session s
JOIN activity_exercise ae ON s.id = ae.session_id
JOIN activity_subtype ast ON ae.activity_subtype_id = ast.id
JOIN exercise_set es ON ae.id = es.exercise_id
LEFT JOIN unit u ON es.weight_unit_id = u.id
WHERE s.id = 1
ORDER BY ae.exercise_order, es.set_number;

-- 9. Calculate total volume for a session
SELECT
    s.id,
    s.session_name,
    s.started_at,
    SUM(es.reps * es.weight) as total_volume,
    'lbs' as unit
FROM activity_session s
JOIN activity_exercise ae ON s.id = ae.session_id
JOIN exercise_set es ON ae.id = es.exercise_id
WHERE s.id = 1
GROUP BY s.id, s.session_name, s.started_at;

-- 10. Get exercise history for a specific exercise (progress tracking)
SELECT
    s.started_at as date,
    ast.name as exercise,
    es.set_number,
    es.reps,
    es.weight,
    u.symbol as unit,
    es.rpe,
    (es.reps * es.weight) as volume
FROM activity_session s
JOIN activity_exercise ae ON s.id = ae.session_id
JOIN activity_subtype ast ON ae.activity_subtype_id = ast.id
JOIN exercise_set es ON ae.id = es.exercise_id
LEFT JOIN unit u ON es.weight_unit_id = u.id
WHERE s.user_id = 1
AND ast.name = 'Bench Press'
AND es.is_warmup = FALSE
AND s.deleted_at IS NULL
ORDER BY s.started_at DESC, es.set_number;

-- 11. Find max weight lifted for each exercise
SELECT
    u.username,
    ast.name as exercise,
    MAX(es.weight) as max_weight,
    unit.symbol as unit,
    MAX(s.started_at) as last_performed
FROM app_user u
JOIN activity_session s ON u.id = s.user_id
JOIN activity_exercise ae ON s.id = ae.session_id
JOIN activity_subtype ast ON ae.activity_subtype_id = ast.id
JOIN exercise_set es ON ae.id = es.exercise_id
LEFT JOIN unit ON es.weight_unit_id = unit.id
WHERE u.id = 1
AND es.is_warmup = FALSE
AND s.deleted_at IS NULL
GROUP BY u.username, ast.name, unit.symbol
ORDER BY max_weight DESC;

-- 12. Get workout volume by muscle group
SELECT
    unnest(ast.muscle_groups) as muscle_group,
    COUNT(DISTINCT s.id) as workouts,
    SUM(es.reps * es.weight) as total_volume,
    'lbs' as unit
FROM activity_session s
JOIN activity_exercise ae ON s.id = ae.session_id
JOIN activity_subtype ast ON ae.activity_subtype_id = ast.id
JOIN exercise_set es ON ae.id = es.exercise_id
WHERE s.user_id = 1
AND s.started_at >= NOW() - INTERVAL '30 days'
AND s.deleted_at IS NULL
GROUP BY muscle_group
ORDER BY total_volume DESC;

-- ============================================================================
-- CARDIO QUERIES
-- ============================================================================

-- 13. Get running statistics for a user
SELECT
    s.started_at as date,
    s.session_name,
    s.duration_minutes,
    MAX(CASE WHEN am.metric_name = 'distance' THEN am.metric_value_numeric END) as distance_km,
    MAX(CASE WHEN am.metric_name = 'average_pace' THEN am.metric_value_numeric END) as avg_pace_min_per_km,
    MAX(CASE WHEN am.metric_name = 'average_heart_rate' THEN am.metric_value_numeric END) as avg_heart_rate,
    MAX(CASE WHEN am.metric_name = 'elevation_gain' THEN am.metric_value_numeric END) as elevation_gain_m,
    s.estimated_calories
FROM activity_session s
LEFT JOIN activity_metric am ON s.id = am.session_id
WHERE s.user_id = 2
AND s.activity_type_id = (SELECT id FROM activity_type WHERE name = 'Running')
AND s.deleted_at IS NULL
GROUP BY s.id, s.started_at, s.session_name, s.duration_minutes, s.estimated_calories
ORDER BY s.started_at DESC;

-- 14. Calculate total distance run this month
SELECT
    u.username,
    DATE_TRUNC('month', s.started_at) as month,
    COUNT(*) as total_runs,
    SUM(am.metric_value_numeric) as total_distance_km,
    ROUND(AVG(s.duration_minutes), 2) as avg_duration_minutes,
    SUM(s.estimated_calories) as total_calories
FROM app_user u
JOIN activity_session s ON u.id = s.user_id
JOIN activity_metric am ON s.id = am.session_id
WHERE u.id = 2
AND s.activity_type_id = (SELECT id FROM activity_type WHERE name = 'Running')
AND am.metric_name = 'distance'
AND s.started_at >= DATE_TRUNC('month', CURRENT_DATE)
AND s.deleted_at IS NULL
GROUP BY u.username, DATE_TRUNC('month', s.started_at);

-- ============================================================================
-- PERSONAL RECORDS QUERIES
-- ============================================================================

-- 15. Get all personal records for a user
SELECT
    pr.id,
    ast.name as exercise,
    pr.record_type,
    pr.record_value,
    u.symbol as unit,
    pr.previous_record_value,
    pr.achieved_at,
    s.session_name,
    pr.notes
FROM personal_record pr
JOIN activity_subtype ast ON pr.activity_subtype_id = ast.id
LEFT JOIN unit u ON pr.unit_id = u.id
JOIN activity_session s ON pr.session_id = s.id
WHERE pr.user_id = 1
ORDER BY pr.achieved_at DESC;

-- 16. Get recent PRs across all users (leaderboard style)
SELECT
    u.username,
    ast.name as exercise,
    pr.record_type,
    pr.record_value,
    unit.symbol as unit,
    pr.achieved_at
FROM personal_record pr
JOIN app_user u ON pr.user_id = u.id
JOIN activity_subtype ast ON pr.activity_subtype_id = ast.id
LEFT JOIN unit ON pr.unit_id = unit.id
WHERE pr.achieved_at >= NOW() - INTERVAL '7 days'
ORDER BY pr.achieved_at DESC;

-- 17. Compare PRs between users for the same exercise
SELECT
    u.username,
    ast.name as exercise,
    pr.record_type,
    pr.record_value,
    unit.symbol as unit,
    pr.achieved_at
FROM personal_record pr
JOIN app_user u ON pr.user_id = u.id
JOIN activity_subtype ast ON pr.activity_subtype_id = ast.id
LEFT JOIN unit ON pr.unit_id = unit.id
WHERE ast.name = 'Deadlift'
AND pr.record_type = 'max_weight'
ORDER BY pr.record_value DESC;

-- ============================================================================
-- GOAL TRACKING QUERIES
-- ============================================================================

-- 18. Get active goals with progress
SELECT
    g.id,
    g.title,
    g.description,
    gt.name as goal_type,
    at.name as activity_type,
    g.target_value,
    u.symbol as unit,
    g.current_value,
    CASE
        WHEN g.target_value > 0 THEN
            ROUND((g.current_value / g.target_value * 100), 2)
        ELSE NULL
    END as progress_percentage,
    g.start_date,
    g.target_date,
    (g.target_date - CURRENT_DATE) as days_remaining,
    g.frequency_per_week
FROM user_goal g
JOIN goal_type gt ON g.goal_type_id = gt.id
LEFT JOIN activity_type at ON g.activity_type_id = at.id
LEFT JOIN unit u ON g.target_unit_id = u.id
WHERE g.user_id = 1
AND g.is_active = TRUE
AND g.is_completed = FALSE
ORDER BY g.target_date;

-- 19. Get goal milestones with achievement status
SELECT
    g.title as goal,
    gm.title as milestone,
    gm.target_value,
    gm.is_achieved,
    gm.achieved_at
FROM user_goal g
JOIN goal_milestone gm ON g.id = gm.goal_id
WHERE g.user_id = 1
ORDER BY g.id, gm.target_value;

-- 20. Calculate goal progress based on recent sessions
-- Example: Update running distance goal with actual mileage
SELECT
    g.title,
    g.current_value as tracked_progress,
    COALESCE(SUM(am.metric_value_numeric), 0) as actual_distance,
    g.target_value as target,
    ROUND((COALESCE(SUM(am.metric_value_numeric), 0) / g.target_value * 100), 2) as completion_percentage
FROM user_goal g
LEFT JOIN activity_session s ON g.user_id = s.user_id
    AND g.activity_type_id = s.activity_type_id
    AND s.started_at >= g.start_date
LEFT JOIN activity_metric am ON s.id = am.session_id
    AND am.metric_name = 'distance'
WHERE g.user_id = 2
AND g.id = 6  -- Sarah's 500 mile goal
GROUP BY g.id, g.title, g.current_value, g.target_value;

-- ============================================================================
-- BODY METRICS QUERIES
-- ============================================================================

-- 21. Get body weight history with trend
SELECT
    bmt.name as metric,
    ubm.value,
    u.symbol as unit,
    ubm.measured_at,
    LAG(ubm.value) OVER (ORDER BY ubm.measured_at) as previous_value,
    ubm.value - LAG(ubm.value) OVER (ORDER BY ubm.measured_at) as change,
    ubm.notes
FROM user_body_metric ubm
JOIN body_metric_type bmt ON ubm.metric_type_id = bmt.id
JOIN unit u ON ubm.unit_id = u.id
WHERE ubm.user_id = 1
AND bmt.name = 'weight'
ORDER BY ubm.measured_at DESC;

-- 22. Get all body measurements for a specific date
SELECT
    bmt.name as metric,
    bmt.category,
    ubm.value,
    u.symbol as unit,
    ubm.measured_at
FROM user_body_metric ubm
JOIN body_metric_type bmt ON ubm.metric_type_id = bmt.id
JOIN unit u ON ubm.unit_id = u.id
WHERE ubm.user_id = 1
AND DATE(ubm.measured_at) = '2025-01-01'
ORDER BY bmt.category, bmt.name;

-- 23. Track body composition changes over time
SELECT
    DATE(ubm.measured_at) as date,
    MAX(CASE WHEN bmt.name = 'weight' THEN ubm.value END) as weight_lbs,
    MAX(CASE WHEN bmt.name = 'body_fat_percentage' THEN ubm.value END) as body_fat_pct,
    MAX(CASE WHEN bmt.name = 'muscle_mass' THEN ubm.value END) as muscle_mass_lbs
FROM user_body_metric ubm
JOIN body_metric_type bmt ON ubm.metric_type_id = bmt.id
WHERE ubm.user_id = 1
AND bmt.name IN ('weight', 'body_fat_percentage', 'muscle_mass')
GROUP BY DATE(ubm.measured_at)
ORDER BY date DESC;

-- ============================================================================
-- WORKOUT PROGRAM QUERIES
-- ============================================================================

-- 24. Get public workout programs with details
SELECT
    wp.id,
    wp.name,
    wp.description,
    wp.difficulty_level,
    wp.duration_weeks,
    wp.sessions_per_week,
    ac.name as category,
    wp.tags,
    COALESCE(u.username, 'System') as creator,
    wp.is_official,
    COUNT(DISTINCT upe.user_id) as enrolled_users
FROM workout_program wp
LEFT JOIN activity_category ac ON wp.category_id = ac.id
LEFT JOIN app_user u ON wp.creator_id = u.id
LEFT JOIN user_program_enrollment upe ON wp.id = upe.program_id AND upe.is_active = TRUE
WHERE wp.is_public = TRUE
AND wp.deleted_at IS NULL
GROUP BY wp.id, wp.name, wp.description, wp.difficulty_level, wp.duration_weeks,
    wp.sessions_per_week, ac.name, wp.tags, u.username, wp.is_official
ORDER BY enrolled_users DESC, wp.name;

-- 25. Get program details with session templates
SELECT
    wp.name as program,
    pst.week_number,
    pst.day_number,
    pst.session_name,
    at.name as activity_type,
    pst.estimated_duration_minutes,
    COUNT(pet.id) as exercise_count
FROM workout_program wp
JOIN program_session_template pst ON wp.id = pst.program_id
JOIN activity_type at ON pst.activity_type_id = at.id
LEFT JOIN program_exercise_template pet ON pst.id = pet.session_template_id
WHERE wp.id = 1
GROUP BY wp.name, pst.week_number, pst.day_number, pst.session_name,
    at.name, pst.estimated_duration_minutes
ORDER BY pst.week_number, pst.day_number;

-- 26. Get full program workout template
SELECT
    pst.week_number,
    pst.day_number,
    pst.session_name,
    pet.exercise_order,
    ast.name as exercise,
    pet.target_sets,
    pet.target_reps,
    pet.target_weight_pct as pct_of_1rm,
    pet.rest_seconds,
    pet.notes
FROM program_session_template pst
JOIN program_exercise_template pet ON pst.id = pet.session_template_id
JOIN activity_subtype ast ON pet.activity_subtype_id = ast.id
WHERE pst.program_id = 1
ORDER BY pst.week_number, pst.day_number, pet.exercise_order;

-- 27. Get user's enrolled programs with progress
SELECT
    wp.name as program,
    upe.start_date,
    upe.current_week,
    upe.current_day,
    wp.duration_weeks as total_weeks,
    ROUND((upe.current_week::NUMERIC / wp.duration_weeks * 100), 2) as progress_percentage,
    upe.is_active,
    upe.completed_at
FROM user_program_enrollment upe
JOIN workout_program wp ON upe.program_id = wp.id
WHERE upe.user_id = 1
ORDER BY upe.is_active DESC, upe.start_date DESC;

-- ============================================================================
-- GAMIFICATION QUERIES
-- ============================================================================

-- 28. Get user's achievements with details
SELECT
    at.name as achievement,
    at.description,
    at.category,
    at.rarity,
    at.points,
    ua.earned_at,
    ua.progress_value,
    s.session_name as related_session
FROM user_achievement ua
JOIN achievement_type at ON ua.achievement_type_id = at.id
LEFT JOIN activity_session s ON ua.related_session_id = s.id
WHERE ua.user_id = 1
ORDER BY ua.earned_at DESC;

-- 29. Get user's total achievement points and rank
SELECT
    u.username,
    COUNT(ua.id) as total_achievements,
    SUM(at.points) as total_points,
    RANK() OVER (ORDER BY SUM(at.points) DESC) as rank
FROM app_user u
LEFT JOIN user_achievement ua ON u.id = ua.user_id
LEFT JOIN achievement_type at ON ua.achievement_type_id = at.id
WHERE u.is_active = TRUE
GROUP BY u.id, u.username
ORDER BY total_points DESC;

-- 30. Get available achievements not yet earned
SELECT
    at.name,
    at.description,
    at.category,
    at.rarity,
    at.points
FROM achievement_type at
WHERE at.id NOT IN (
    SELECT achievement_type_id
    FROM user_achievement
    WHERE user_id = 5
)
ORDER BY at.points DESC;

-- 31. Get user's activity streaks
SELECT
    COALESCE(at.name, 'Overall') as activity,
    us.current_streak_days,
    us.longest_streak_days,
    us.last_activity_date,
    CASE
        WHEN us.last_activity_date = CURRENT_DATE THEN 'Active Today'
        WHEN us.last_activity_date = CURRENT_DATE - 1 THEN 'Active Yesterday'
        ELSE 'Streak Broken'
    END as status
FROM user_streak us
LEFT JOIN activity_type at ON us.activity_type_id = at.id
WHERE us.user_id = 2
ORDER BY us.current_streak_days DESC;

-- ============================================================================
-- SOCIAL QUERIES
-- ============================================================================

-- 32. Get user's social feed (sessions from followed users)
SELECT
    u.username,
    u.avatar_url,
    s.id as session_id,
    s.session_name,
    at.name as activity_type,
    s.started_at,
    s.duration_minutes,
    s.rating,
    ss.share_message,
    ss.visibility,
    (SELECT COUNT(*) FROM session_like WHERE session_id = s.id) as like_count,
    (SELECT COUNT(*) FROM session_comment WHERE session_id = s.id AND deleted_at IS NULL) as comment_count
FROM user_relationship ur
JOIN app_user u ON ur.following_id = u.id
JOIN activity_session s ON u.id = s.user_id
JOIN activity_type at ON s.activity_type_id = at.id
JOIN session_share ss ON s.id = ss.session_id
WHERE ur.follower_id = 1
AND s.deleted_at IS NULL
AND (ss.visibility = 'public' OR ss.visibility = 'friends')
ORDER BY s.started_at DESC
LIMIT 20;

-- 33. Get session with comments and likes
SELECT
    s.id,
    s.session_name,
    u.username as session_owner,
    s.started_at,
    at.name as activity_type,
    ss.share_message,
    (SELECT COUNT(*) FROM session_like WHERE session_id = s.id) as total_likes,
    (SELECT COUNT(*) FROM session_comment WHERE session_id = s.id AND deleted_at IS NULL) as total_comments
FROM activity_session s
JOIN app_user u ON s.user_id = u.id
JOIN activity_type at ON s.activity_type_id = at.id
LEFT JOIN session_share ss ON s.id = ss.session_id
WHERE s.id = 3;

-- Get comments for the session
SELECT
    u.username,
    u.avatar_url,
    sc.comment_text,
    sc.created_at
FROM session_comment sc
JOIN app_user u ON sc.user_id = u.id
WHERE sc.session_id = 3
AND sc.deleted_at IS NULL
ORDER BY sc.created_at;

-- 34. Get users who liked a session
SELECT
    u.username,
    u.avatar_url,
    sl.created_at as liked_at
FROM session_like sl
JOIN app_user u ON sl.user_id = u.id
WHERE sl.session_id = 3
ORDER BY sl.created_at DESC;

-- 35. Find suggested users to follow (users with similar activities)
SELECT DISTINCT
    u.id,
    u.username,
    u.avatar_url,
    COUNT(DISTINCT s.activity_type_id) as common_activities,
    (SELECT COUNT(*) FROM session_share ss
     JOIN activity_session s2 ON ss.session_id = s2.id
     WHERE s2.user_id = u.id AND ss.visibility = 'public') as public_sessions
FROM app_user u
JOIN activity_session s ON u.id = s.user_id
WHERE s.activity_type_id IN (
    SELECT DISTINCT activity_type_id
    FROM activity_session
    WHERE user_id = 1
    AND deleted_at IS NULL
)
AND u.id != 1
AND u.id NOT IN (
    SELECT following_id
    FROM user_relationship
    WHERE follower_id = 1
)
AND u.is_active = TRUE
GROUP BY u.id, u.username, u.avatar_url
HAVING COUNT(DISTINCT s.activity_type_id) >= 2
ORDER BY common_activities DESC, public_sessions DESC
LIMIT 10;

-- ============================================================================
-- ANALYTICS & DASHBOARD QUERIES
-- ============================================================================

-- 36. Get user dashboard statistics (using materialized view)
SELECT
    u.username,
    us.total_sessions,
    us.total_days_active,
    us.last_activity,
    ROUND(us.total_minutes / 60.0, 2) as total_hours,
    ROUND(us.avg_session_rating, 2) as avg_rating,
    ROUND(us.total_calories, 0) as total_calories,
    us.total_prs
FROM user_statistics us
JOIN app_user u ON us.user_id = u.id
WHERE u.id = 1;

-- 37. Get weekly activity summary
SELECT
    DATE_TRUNC('week', s.started_at) as week,
    COUNT(*) as sessions,
    COUNT(DISTINCT DATE(s.started_at)) as active_days,
    SUM(s.duration_minutes) as total_minutes,
    ROUND(AVG(s.rating), 2) as avg_rating,
    SUM(s.estimated_calories) as total_calories
FROM activity_session s
WHERE s.user_id = 1
AND s.started_at >= NOW() - INTERVAL '12 weeks'
AND s.deleted_at IS NULL
GROUP BY DATE_TRUNC('week', s.started_at)
ORDER BY week DESC;

-- 38. Get monthly activity comparison
SELECT
    TO_CHAR(s.started_at, 'YYYY-MM') as month,
    COUNT(*) as sessions,
    SUM(s.duration_minutes) as total_minutes,
    ROUND(AVG(s.rating), 2) as avg_rating,
    COUNT(*) FILTER (WHERE s.is_personal_record = TRUE) as prs_achieved,
    SUM(s.estimated_calories) as total_calories
FROM activity_session s
WHERE s.user_id = 1
AND s.started_at >= DATE_TRUNC('year', CURRENT_DATE)
AND s.deleted_at IS NULL
GROUP BY TO_CHAR(s.started_at, 'YYYY-MM')
ORDER BY month DESC;

-- 39. Get activity heatmap data (sessions by day of week and hour)
SELECT
    TO_CHAR(s.started_at, 'Day') as day_of_week,
    EXTRACT(HOUR FROM s.started_at) as hour_of_day,
    COUNT(*) as session_count
FROM activity_session s
WHERE s.user_id = 1
AND s.deleted_at IS NULL
GROUP BY TO_CHAR(s.started_at, 'Day'), EXTRACT(HOUR FROM s.started_at)
ORDER BY
    CASE TO_CHAR(s.started_at, 'Day')
        WHEN 'Monday   ' THEN 1
        WHEN 'Tuesday  ' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday ' THEN 4
        WHEN 'Friday   ' THEN 5
        WHEN 'Saturday ' THEN 6
        WHEN 'Sunday   ' THEN 7
    END,
    hour_of_day;

-- 40. Get performance trends for specific exercise
WITH exercise_history AS (
    SELECT
        DATE(s.started_at) as workout_date,
        AVG(es.weight) as avg_weight,
        MAX(es.weight) as max_weight,
        SUM(es.reps * es.weight) as total_volume
    FROM activity_session s
    JOIN activity_exercise ae ON s.id = ae.session_id
    JOIN activity_subtype ast ON ae.activity_subtype_id = ast.id
    JOIN exercise_set es ON ae.id = es.exercise_id
    WHERE s.user_id = 1
    AND ast.name = 'Bench Press'
    AND es.is_warmup = FALSE
    AND s.deleted_at IS NULL
    GROUP BY DATE(s.started_at)
)
SELECT
    workout_date,
    ROUND(avg_weight, 2) as avg_weight,
    max_weight,
    total_volume,
    ROUND(AVG(avg_weight) OVER (ORDER BY workout_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) as moving_avg_3
FROM exercise_history
ORDER BY workout_date DESC;

-- ============================================================================
-- SEARCH QUERIES
-- ============================================================================

-- 41. Full-text search for sessions
SELECT
    s.id,
    s.session_name,
    at.name as activity_type,
    s.started_at,
    s.notes
FROM activity_session s
JOIN activity_type at ON s.activity_type_id = at.id
WHERE s.user_id = 1
AND s.search_vector @@ to_tsquery('english', 'bench & press')
AND s.deleted_at IS NULL
ORDER BY s.started_at DESC;

-- 42. Search exercises by name or muscle group
SELECT
    ast.name,
    at.name as activity_type,
    ast.muscle_groups,
    ast.difficulty_level,
    ast.description
FROM activity_subtype ast
JOIN activity_type at ON ast.activity_type_id = at.id
WHERE
    ast.name ILIKE '%squat%'
    OR 'quadriceps' = ANY(ast.muscle_groups)
ORDER BY ast.name;

-- 43. Search workout programs
SELECT
    wp.name,
    wp.description,
    wp.difficulty_level,
    wp.duration_weeks,
    wp.tags
FROM workout_program wp
WHERE
    wp.search_vector @@ to_tsquery('english', 'strength')
    AND wp.is_public = TRUE
    AND wp.deleted_at IS NULL
ORDER BY wp.is_official DESC, wp.name;

-- ============================================================================
-- MAINTENANCE QUERIES
-- ============================================================================

-- 44. Refresh materialized view
REFRESH MATERIALIZED VIEW user_statistics;

-- 45. Find orphaned records (sessions without exercises for strength training)
SELECT
    s.id,
    s.session_name,
    s.started_at,
    at.name as activity_type
FROM activity_session s
JOIN activity_type at ON s.activity_type_id = at.id
LEFT JOIN activity_exercise ae ON s.id = ae.session_id
WHERE at.name = 'Weight Training'
AND ae.id IS NULL
AND s.deleted_at IS NULL;

-- 46. Get data quality report
SELECT
    'Total Users' as metric,
    COUNT(*)::TEXT as value
FROM app_user WHERE deleted_at IS NULL
UNION ALL
SELECT
    'Active Users (last 30 days)',
    COUNT(DISTINCT user_id)::TEXT
FROM activity_session
WHERE started_at >= NOW() - INTERVAL '30 days'
AND deleted_at IS NULL
UNION ALL
SELECT
    'Total Sessions',
    COUNT(*)::TEXT
FROM activity_session WHERE deleted_at IS NULL
UNION ALL
SELECT
    'Sessions with PRs',
    COUNT(*)::TEXT
FROM activity_session WHERE is_personal_record = TRUE AND deleted_at IS NULL
UNION ALL
SELECT
    'Active Goals',
    COUNT(*)::TEXT
FROM user_goal WHERE is_active = TRUE AND is_completed = FALSE
UNION ALL
SELECT
    'Total Achievements Earned',
    COUNT(*)::TEXT
FROM user_achievement;

-- ============================================================================
-- ADVANCED ANALYTICAL QUERIES
-- ============================================================================

-- 47. Calculate estimated 1RM using Epley formula
SELECT
    u.username,
    ast.name as exercise,
    es.weight,
    es.reps,
    ROUND(es.weight * (1 + es.reps / 30.0), 2) as estimated_1rm,
    s.started_at
FROM exercise_set es
JOIN activity_exercise ae ON es.exercise_id = ae.id
JOIN activity_session s ON ae.session_id = s.id
JOIN app_user u ON s.user_id = u.id
JOIN activity_subtype ast ON ae.activity_subtype_id = ast.id
WHERE u.id = 1
AND ast.name IN ('Bench Press', 'Squat', 'Deadlift')
AND es.reps BETWEEN 1 AND 10
AND es.is_warmup = FALSE
ORDER BY s.started_at DESC, estimated_1rm DESC;

-- 48. Find training consistency (days between workouts)
WITH session_gaps AS (
    SELECT
        user_id,
        started_at,
        LAG(started_at) OVER (PARTITION BY user_id ORDER BY started_at) as previous_session,
        EXTRACT(DAY FROM started_at - LAG(started_at) OVER (PARTITION BY user_id ORDER BY started_at)) as days_gap
    FROM activity_session
    WHERE deleted_at IS NULL
)
SELECT
    u.username,
    ROUND(AVG(sg.days_gap), 2) as avg_days_between_workouts,
    MIN(sg.days_gap) as min_gap,
    MAX(sg.days_gap) as max_gap,
    COUNT(*) as total_sessions
FROM session_gaps sg
JOIN app_user u ON sg.user_id = u.id
WHERE sg.days_gap IS NOT NULL
AND sg.started_at >= NOW() - INTERVAL '90 days'
GROUP BY u.username
ORDER BY avg_days_between_workouts;

-- 49. Workout time preferences analysis
SELECT
    u.username,
    CASE
        WHEN EXTRACT(HOUR FROM s.started_at) BETWEEN 5 AND 11 THEN 'Morning (5am-11am)'
        WHEN EXTRACT(HOUR FROM s.started_at) BETWEEN 12 AND 16 THEN 'Afternoon (12pm-4pm)'
        WHEN EXTRACT(HOUR FROM s.started_at) BETWEEN 17 AND 21 THEN 'Evening (5pm-9pm)'
        ELSE 'Night (10pm-4am)'
    END as time_period,
    COUNT(*) as session_count,
    ROUND(AVG(s.rating), 2) as avg_rating,
    ROUND(AVG(s.duration_minutes), 2) as avg_duration
FROM activity_session s
JOIN app_user u ON s.user_id = u.id
WHERE s.deleted_at IS NULL
GROUP BY u.username, time_period
ORDER BY u.username, session_count DESC;

-- 50. Generate workout summary report
SELECT
    TO_CHAR(s.started_at, 'YYYY-MM-DD') as date,
    at.name as activity,
    s.session_name,
    s.duration_minutes || ' min' as duration,
    COALESCE(s.rating::TEXT, '-') || '/10' as rating,
    COALESCE(ROUND(s.estimated_calories, 0)::TEXT, '-') as calories,
    CASE WHEN s.is_personal_record THEN '🏆 PR' ELSE '' END as highlights
FROM activity_session s
JOIN activity_type at ON s.activity_type_id = at.id
WHERE s.user_id = 1
AND s.started_at >= NOW() - INTERVAL '7 days'
AND s.deleted_at IS NULL
ORDER BY s.started_at DESC;

-- ============================================================================
-- END OF SAMPLE QUERIES
-- ============================================================================
