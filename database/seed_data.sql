-- ============================================================================
-- Activity Tracker Sample Data
-- Version: 2.0
-- This script provides comprehensive sample data for testing and development
-- ============================================================================

-- Clear existing data (in reverse dependency order)
TRUNCATE TABLE session_like, session_comment, session_share, user_relationship,
    user_streak, user_achievement, achievement_type, user_program_enrollment,
    program_exercise_template, program_session_template, workout_program,
    user_body_metric, body_metric_type, personal_record, goal_milestone, user_goal,
    goal_type, session_media, activity_type_metric_template, activity_metric,
    exercise_set, activity_exercise, activity_session, activity_subtype,
    activity_type, activity_category, app_user, unit
RESTART IDENTITY CASCADE;

-- ============================================================================
-- Units of Measurement
-- ============================================================================

INSERT INTO unit (name, symbol, type, conversion_factor, is_base_unit) VALUES
-- Weight units
('kilograms', 'kg', 'weight', 1.0, TRUE),
('pounds', 'lbs', 'weight', 0.453592, FALSE),
('grams', 'g', 'weight', 0.001, FALSE),

-- Distance units
('kilometers', 'km', 'distance', 1.0, TRUE),
('miles', 'mi', 'distance', 1.60934, FALSE),
('meters', 'm', 'distance', 0.001, FALSE),
('feet', 'ft', 'distance', 0.0003048, FALSE),

-- Time units
('seconds', 's', 'time', 1.0, TRUE),
('minutes', 'min', 'time', 60.0, FALSE),
('hours', 'h', 'time', 3600.0, FALSE),

-- Count units
('repetitions', 'reps', 'count', 1.0, TRUE),
('sets', 'sets', 'count', 1.0, FALSE),
('count', 'count', 'count', 1.0, FALSE),

-- Speed units
('kilometers per hour', 'km/h', 'speed', 1.0, TRUE),
('miles per hour', 'mph', 'speed', 1.60934, FALSE),
('meters per second', 'm/s', 'speed', 3.6, FALSE),

-- Energy units
('calories', 'cal', 'energy', 1.0, TRUE),
('kilojoules', 'kJ', 'energy', 0.239006, FALSE),

-- Percentage
('percentage', '%', 'percentage', 1.0, TRUE),

-- Body measurement units
('centimeters', 'cm', 'distance', 0.00001, FALSE),
('inches', 'in', 'distance', 0.0000254, FALSE);

-- ============================================================================
-- Users
-- ============================================================================

INSERT INTO app_user (username, email, password_hash, first_name, last_name, avatar_url,
    timezone, measurement_preference, weight_unit_id, distance_unit_id, is_active, email_verified) VALUES
('john_lifter', 'john@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5oDJ.L7JQXL6K',
    'John', 'Smith', 'https://example.com/avatars/john.jpg',
    'America/New_York', 'imperial', 2, 2, TRUE, TRUE),

('sarah_runner', 'sarah@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5oDJ.L7JQXL6K',
    'Sarah', 'Johnson', 'https://example.com/avatars/sarah.jpg',
    'America/Los_Angeles', 'metric', 1, 1, TRUE, TRUE),

('mike_yoga', 'mike@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5oDJ.L7JQXL6K',
    'Michael', 'Chen', 'https://example.com/avatars/mike.jpg',
    'Asia/Tokyo', 'metric', 1, 1, TRUE, TRUE),

('emma_athlete', 'emma@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5oDJ.L7JQXL6K',
    'Emma', 'Williams', 'https://example.com/avatars/emma.jpg',
    'Europe/London', 'metric', 1, 1, TRUE, TRUE),

('alex_creative', 'alex@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5oDJ.L7JQXL6K',
    'Alex', 'Taylor', 'https://example.com/avatars/alex.jpg',
    'America/Chicago', 'imperial', 2, 2, TRUE, TRUE);

-- ============================================================================
-- Activity Hierarchy
-- ============================================================================

-- Categories
INSERT INTO activity_category (name, description, icon_name, display_order) VALUES
('Physical', 'Physical fitness and exercise activities', 'dumbbell', 1),
('Creative', 'Creative and artistic pursuits', 'palette', 2),
('Wellness', 'Mental health and wellness activities', 'heart', 3),
('Cognitive', 'Mental and cognitive activities', 'brain', 4),
('Social', 'Social and community activities', 'users', 5);

-- Activity Types
INSERT INTO activity_type (name, category_id, is_physical, has_duration, has_intensity, description) VALUES
-- Physical activities
('Weight Training', 1, TRUE, TRUE, TRUE, 'Resistance training with weights'),
('Running', 1, TRUE, TRUE, TRUE, 'Running and jogging activities'),
('Cycling', 1, TRUE, TRUE, TRUE, 'Indoor and outdoor cycling'),
('Swimming', 1, TRUE, TRUE, TRUE, 'Swimming activities'),
('Yoga', 1, TRUE, TRUE, FALSE, 'Yoga practice and poses'),
('Pilates', 1, TRUE, TRUE, FALSE, 'Pilates exercises'),
('Hiking', 1, TRUE, TRUE, FALSE, 'Outdoor hiking'),
('CrossFit', 1, TRUE, TRUE, TRUE, 'CrossFit workouts'),

-- Creative activities
('Painting', 2, FALSE, TRUE, FALSE, 'Painting and drawing'),
('Music Practice', 2, FALSE, TRUE, FALSE, 'Musical instrument practice'),
('Dance', 2, TRUE, TRUE, FALSE, 'Dance practice and performance'),
('Writing', 2, FALSE, TRUE, FALSE, 'Creative writing'),

-- Wellness activities
('Meditation', 3, FALSE, TRUE, FALSE, 'Meditation and mindfulness'),
('Breathing Exercises', 3, FALSE, TRUE, FALSE, 'Breathing techniques'),
('Massage', 3, FALSE, TRUE, FALSE, 'Massage therapy'),

-- Cognitive activities
('Chess', 4, FALSE, TRUE, FALSE, 'Chess games and study'),
('Reading', 4, FALSE, TRUE, FALSE, 'Reading books and articles'),

-- Social activities
('Team Sports', 5, TRUE, TRUE, TRUE, 'Team-based sports activities');

-- Activity Subtypes (Exercises)
INSERT INTO activity_subtype (activity_type_id, name, description, default_sets, default_reps,
    default_weight, default_weight_unit, muscle_groups, difficulty_level, equipment_needed) VALUES

-- Weight Training exercises
(1, 'Barbell Squat', 'Compound lower body exercise', 3, 8, 100, 'lbs',
    ARRAY['quadriceps', 'glutes', 'hamstrings'], 'intermediate', ARRAY['barbell', 'squat rack']),
(1, 'Bench Press', 'Compound chest exercise', 3, 8, 135, 'lbs',
    ARRAY['chest', 'triceps', 'shoulders'], 'intermediate', ARRAY['barbell', 'bench']),
(1, 'Deadlift', 'Full body compound lift', 3, 5, 225, 'lbs',
    ARRAY['back', 'glutes', 'hamstrings', 'traps'], 'advanced', ARRAY['barbell']),
(1, 'Overhead Press', 'Shoulder strength exercise', 3, 8, 95, 'lbs',
    ARRAY['shoulders', 'triceps', 'core'], 'intermediate', ARRAY['barbell']),
(1, 'Pull-ups', 'Upper back and bicep exercise', 3, 8, 0, 'lbs',
    ARRAY['lats', 'biceps', 'traps'], 'intermediate', ARRAY['pull-up bar']),
(1, 'Dumbbell Rows', 'Back thickness exercise', 3, 10, 50, 'lbs',
    ARRAY['lats', 'rhomboids', 'traps'], 'beginner', ARRAY['dumbbells', 'bench']),
(1, 'Romanian Deadlift', 'Hamstring focused exercise', 3, 10, 135, 'lbs',
    ARRAY['hamstrings', 'glutes', 'lower back'], 'intermediate', ARRAY['barbell']),
(1, 'Leg Press', 'Quad and glute exercise', 3, 12, 200, 'lbs',
    ARRAY['quadriceps', 'glutes'], 'beginner', ARRAY['leg press machine']),
(1, 'Lat Pulldown', 'Lat width exercise', 3, 10, 120, 'lbs',
    ARRAY['lats', 'biceps'], 'beginner', ARRAY['cable machine']),
(1, 'Bicep Curls', 'Bicep isolation', 3, 12, 30, 'lbs',
    ARRAY['biceps'], 'beginner', ARRAY['dumbbells']),

-- Yoga poses
(5, 'Downward Dog', 'Foundational inversion pose', NULL, NULL, NULL, NULL,
    ARRAY['shoulders', 'hamstrings', 'calves'], 'beginner', ARRAY['yoga mat']),
(5, 'Warrior I', 'Standing strength pose', NULL, NULL, NULL, NULL,
    ARRAY['legs', 'core', 'arms'], 'beginner', ARRAY['yoga mat']),
(5, 'Warrior II', 'Hip opening warrior pose', NULL, NULL, NULL, NULL,
    ARRAY['legs', 'hips', 'core'], 'beginner', ARRAY['yoga mat']),
(5, 'Tree Pose', 'Balance and focus pose', NULL, NULL, NULL, NULL,
    ARRAY['legs', 'core', 'ankles'], 'beginner', ARRAY['yoga mat']),
(5, 'Triangle Pose', 'Standing side stretch', NULL, NULL, NULL, NULL,
    ARRAY['legs', 'hips', 'obliques'], 'beginner', ARRAY['yoga mat']),

-- Music subtypes
(10, 'Guitar Practice', 'Acoustic or electric guitar practice', NULL, NULL, NULL, NULL,
    ARRAY['fingers', 'coordination'], 'beginner', ARRAY['guitar']),
(10, 'Piano Scales', 'Piano technique practice', NULL, NULL, NULL, NULL,
    ARRAY['fingers', 'coordination'], 'beginner', ARRAY['piano']),
(10, 'Vocal Exercises', 'Voice training and warmups', NULL, NULL, NULL, NULL,
    ARRAY['vocal cords', 'breath'], 'beginner', ARRAY['none']);

-- ============================================================================
-- Activity Type Metric Templates
-- ============================================================================

INSERT INTO activity_type_metric_template (activity_type_id, metric_name, unit_id, is_required, display_order, input_type) VALUES
-- Running metrics
(2, 'distance', 1, TRUE, 1, 'number'),
(2, 'average_pace', 16, FALSE, 2, 'duration'),
(2, 'max_heart_rate', 12, FALSE, 3, 'number'),
(2, 'average_heart_rate', 12, FALSE, 4, 'number'),
(2, 'elevation_gain', 3, FALSE, 5, 'number'),

-- Cycling metrics
(3, 'distance', 1, TRUE, 1, 'number'),
(3, 'average_speed', 15, FALSE, 2, 'number'),
(3, 'max_speed', 15, FALSE, 3, 'number'),
(3, 'cadence', 12, FALSE, 4, 'number'),
(3, 'elevation_gain', 3, FALSE, 5, 'number'),

-- Swimming metrics
(4, 'distance', 3, TRUE, 1, 'number'),
(4, 'laps', 12, FALSE, 2, 'number'),
(4, 'stroke_type', NULL, FALSE, 3, 'text'),

-- Yoga metrics
(5, 'poses_held', 12, FALSE, 1, 'number'),
(5, 'balance_time', 7, FALSE, 2, 'duration'),
(5, 'flexibility_score', 20, FALSE, 3, 'number'),

-- Meditation metrics
(13, 'focus_rating', 20, FALSE, 1, 'number'),
(13, 'calm_rating', 20, FALSE, 2, 'number'),

-- Music practice metrics
(10, 'pieces_practiced', 12, FALSE, 1, 'number'),
(10, 'scales_completed', 12, FALSE, 2, 'number'),
(10, 'practice_notes', NULL, FALSE, 3, 'text'),

-- Painting metrics
(9, 'canvas_size', NULL, FALSE, 1, 'text'),
(9, 'medium', NULL, FALSE, 2, 'text'),
(9, 'pieces_completed', 12, FALSE, 3, 'number');

-- ============================================================================
-- Goal Types
-- ============================================================================

INSERT INTO goal_type (name, description, icon_name) VALUES
('frequency', 'Exercise frequency goals (sessions per week)', 'calendar'),
('performance', 'Performance improvement goals (speed, weight, etc.)', 'trending-up'),
('habit', 'Habit building goals (consistency)', 'check-circle'),
('time_based', 'Time-based goals (total hours)', 'clock'),
('body_composition', 'Body composition goals (weight, body fat)', 'activity'),
('milestone', 'Achievement milestone goals', 'award');

-- ============================================================================
-- Body Metric Types
-- ============================================================================

INSERT INTO body_metric_type (name, category, default_unit_id, description) VALUES
('weight', 'weight', 1, 'Body weight'),
('body_fat_percentage', 'composition', 20, 'Body fat percentage'),
('muscle_mass', 'composition', 1, 'Lean muscle mass'),
('chest', 'measurement', 22, 'Chest circumference'),
('waist', 'measurement', 22, 'Waist circumference'),
('hips', 'measurement', 22, 'Hip circumference'),
('biceps', 'measurement', 22, 'Bicep circumference'),
('thighs', 'measurement', 22, 'Thigh circumference'),
('calves', 'measurement', 22, 'Calf circumference'),
('resting_heart_rate', 'vital', 12, 'Resting heart rate (bpm)'),
('blood_pressure_systolic', 'vital', 12, 'Systolic blood pressure'),
('blood_pressure_diastolic', 'vital', 12, 'Diastolic blood pressure');

-- ============================================================================
-- Achievement Types
-- ============================================================================

INSERT INTO achievement_type (name, description, badge_icon_url, category, points, rarity, criteria_json) VALUES
('First Workout', 'Complete your first workout session', 'https://example.com/badges/first.png',
    'milestone', 10, 'common', '{"sessions": 1}'),
('Week Warrior', 'Complete 7 consecutive days of activity', 'https://example.com/badges/week.png',
    'streak', 50, 'uncommon', '{"streak_days": 7}'),
('Month Champion', 'Complete 30 consecutive days of activity', 'https://example.com/badges/month.png',
    'streak', 200, 'rare', '{"streak_days": 30}'),
('Century Club', 'Complete 100 total workouts', 'https://example.com/badges/century.png',
    'milestone', 500, 'epic', '{"total_sessions": 100}'),
('Iron Lifter', 'Lift a total of 100,000 lbs', 'https://example.com/badges/iron.png',
    'volume', 300, 'rare', '{"total_volume": 100000}'),
('Marathon Runner', 'Run a total of 26.2 miles in sessions', 'https://example.com/badges/marathon.png',
    'milestone', 250, 'rare', '{"total_distance": 42.195}'),
('Yoga Master', 'Complete 50 yoga sessions', 'https://example.com/badges/yoga.png',
    'milestone', 150, 'uncommon', '{"yoga_sessions": 50}'),
('Early Bird', 'Complete 10 workouts before 7 AM', 'https://example.com/badges/early.png',
    'milestone', 100, 'uncommon', '{"early_sessions": 10}'),
('PR Breaker', 'Break 10 personal records', 'https://example.com/badges/pr.png',
    'milestone', 200, 'rare', '{"personal_records": 10}'),
('Social Butterfly', 'Follow 10 friends', 'https://example.com/badges/social.png',
    'milestone', 50, 'common', '{"followers": 10}');

-- ============================================================================
-- Sample Activity Sessions
-- ============================================================================

-- John's weight training sessions
INSERT INTO activity_session (user_id, activity_type_id, session_name, started_at, ended_at,
    location, rating, perceived_exertion, notes, estimated_calories) VALUES
(1, 1, 'Upper Body Power Day', '2025-01-06 06:00:00', '2025-01-06 07:15:00',
    'Gold''s Gym', 9, 8, 'Great session, felt strong on bench press', 450),
(1, 1, 'Lower Body Strength', '2025-01-08 06:00:00', '2025-01-08 07:30:00',
    'Gold''s Gym', 8, 9, 'Squats were challenging but good', 520),
(1, 1, 'Back and Biceps', '2025-01-10 06:00:00', '2025-01-10 07:00:00',
    'Gold''s Gym', 9, 7, 'New PR on deadlifts!', 480),

-- Sarah's running sessions
(2, 2, 'Morning Run', '2025-01-06 07:00:00', '2025-01-06 07:45:00',
    'Central Park', 8, 6, 'Perfect weather for a run', 380),
(2, 2, 'Interval Training', '2025-01-08 06:30:00', '2025-01-08 07:15:00',
    'Track', 9, 8, 'Pushed hard on the intervals', 420),
(2, 2, 'Long Distance Run', '2025-01-12 07:00:00', '2025-01-12 08:30:00',
    'River Trail', 8, 7, 'Good endurance building session', 650),

-- Mike's yoga sessions
(3, 5, 'Morning Vinyasa Flow', '2025-01-06 07:30:00', '2025-01-06 08:30:00',
    'Home', 9, 5, 'Great way to start the day', 200),
(3, 5, 'Evening Yin Yoga', '2025-01-07 19:00:00', '2025-01-07 20:00:00',
    'Zen Studio', 10, 3, 'Very relaxing and restorative', 150),
(3, 5, 'Power Yoga', '2025-01-09 07:30:00', '2025-01-09 08:45:00',
    'Home', 8, 7, 'Challenging poses today', 280),

-- Emma's CrossFit
(4, 8, 'CrossFit WOD', '2025-01-06 17:00:00', '2025-01-06 18:00:00',
    'CrossFit Box', 9, 9, 'Intense AMRAP workout', 550),
(4, 8, 'CrossFit Strength', '2025-01-08 17:00:00', '2025-01-08 18:15:00',
    'CrossFit Box', 8, 8, 'Focus on Olympic lifts', 480),

-- Alex's creative sessions
(5, 10, 'Guitar Practice Session', '2025-01-06 20:00:00', '2025-01-06 21:30:00',
    'Home', 8, NULL, 'Worked on fingerpicking patterns', NULL),
(5, 9, 'Oil Painting', '2025-01-07 14:00:00', '2025-01-07 17:00:00',
    'Studio', 9, NULL, 'Started new landscape piece', NULL);

-- ============================================================================
-- Activity Exercises and Sets (for Weight Training)
-- ============================================================================

-- John's Upper Body session exercises
INSERT INTO activity_exercise (session_id, activity_subtype_id, exercise_order, superset_group, notes) VALUES
(1, 2, 1, NULL, 'Bench press felt strong today'),
(1, 4, 2, NULL, 'Overhead press'),
(1, 9, 3, 1, 'Superset with tricep dips'),
(1, 10, 4, NULL, 'Finished with bicep curls');

-- Bench Press sets
INSERT INTO exercise_set (exercise_id, set_number, reps, weight, weight_unit_id, rest_seconds, rpe, is_warmup) VALUES
(1, 1, 10, 135, 2, 120, 6, TRUE),
(1, 2, 8, 185, 2, 180, 7, FALSE),
(1, 3, 6, 205, 2, 180, 8, FALSE),
(1, 4, 5, 215, 2, 180, 9, FALSE);

-- Overhead Press sets
INSERT INTO exercise_set (exercise_id, set_number, reps, weight, weight_unit_id, rest_seconds, rpe) VALUES
(2, 1, 8, 95, 2, 120, 7),
(2, 2, 8, 105, 2, 120, 8),
(2, 3, 6, 115, 2, 120, 9);

-- Lat Pulldown sets
INSERT INTO exercise_set (exercise_id, set_number, reps, weight, weight_unit_id, rest_seconds, rpe) VALUES
(3, 1, 10, 120, 2, 90, 7),
(3, 2, 10, 130, 2, 90, 8),
(3, 3, 8, 140, 2, 90, 9);

-- Bicep Curls sets
INSERT INTO exercise_set (exercise_id, set_number, reps, weight, weight_unit_id, rest_seconds, rpe) VALUES
(4, 1, 12, 30, 2, 60, 6),
(4, 2, 10, 35, 2, 60, 7),
(4, 3, 8, 35, 2, 60, 8);

-- John's Lower Body session exercises
INSERT INTO activity_exercise (session_id, activity_subtype_id, exercise_order, notes) VALUES
(2, 1, 1, 'Squats - felt heavy but good form'),
(2, 7, 2, 'Romanian deadlifts for hamstrings'),
(2, 8, 3, 'Leg press to finish');

-- Squat sets
INSERT INTO exercise_set (exercise_id, set_number, reps, weight, weight_unit_id, rest_seconds, rpe) VALUES
(5, 1, 10, 135, 2, 180, 6),
(5, 2, 8, 185, 2, 180, 7),
(5, 3, 6, 225, 2, 180, 8),
(5, 4, 5, 245, 2, 240, 9);

-- RDL sets
INSERT INTO exercise_set (exercise_id, set_number, reps, weight, weight_unit_id, rest_seconds, rpe) VALUES
(6, 1, 10, 135, 2, 120, 6),
(6, 2, 10, 155, 2, 120, 7),
(6, 3, 8, 175, 2, 120, 8);

-- Leg press sets
INSERT INTO exercise_set (exercise_id, set_number, reps, weight, weight_unit_id, rest_seconds, rpe) VALUES
(7, 1, 12, 270, 2, 90, 7),
(7, 2, 12, 315, 2, 90, 8),
(7, 3, 10, 360, 2, 90, 9);

-- John's Back session exercises
INSERT INTO activity_exercise (session_id, activity_subtype_id, exercise_order, notes) VALUES
(3, 3, 1, 'Deadlift - new PR!'),
(3, 6, 2, 'Dumbbell rows'),
(3, 10, 3, 'Bicep curls');

-- Deadlift sets (PR achieved)
INSERT INTO exercise_set (exercise_id, set_number, reps, weight, weight_unit_id, rest_seconds, rpe) VALUES
(8, 1, 8, 225, 2, 180, 6),
(8, 2, 5, 275, 2, 240, 7),
(8, 3, 3, 315, 2, 300, 8),
(8, 4, 1, 365, 2, 300, 10);

-- Dumbbell row sets
INSERT INTO exercise_set (exercise_id, set_number, reps, weight, weight_unit_id, rest_seconds, rpe) VALUES
(9, 1, 10, 50, 2, 90, 7),
(9, 2, 10, 55, 2, 90, 8),
(9, 3, 8, 60, 2, 90, 9);

-- Bicep curl sets
INSERT INTO exercise_set (exercise_id, set_number, reps, weight, weight_unit_id, rest_seconds, rpe) VALUES
(10, 1, 12, 30, 2, 60, 6),
(10, 2, 10, 35, 2, 60, 8),
(10, 3, 10, 35, 2, 60, 8);

-- ============================================================================
-- Activity Metrics (for non-strength activities)
-- ============================================================================

-- Sarah's running metrics
INSERT INTO activity_metric (session_id, metric_name, metric_value_numeric, unit_id) VALUES
(4, 'distance', 5.2, 1),
(4, 'average_pace', 5.5, 7),
(4, 'max_heart_rate', 165, 12),
(4, 'average_heart_rate', 145, 12),

(5, 'distance', 6.5, 1),
(5, 'average_pace', 5.0, 7),
(5, 'max_heart_rate', 178, 12),
(5, 'average_heart_rate', 158, 12),

(6, 'distance', 15.3, 1),
(6, 'average_pace', 6.2, 7),
(6, 'max_heart_rate', 158, 12),
(6, 'average_heart_rate', 142, 12),
(6, 'elevation_gain', 125, 3);

-- Mike's yoga metrics
INSERT INTO activity_metric (session_id, metric_name, metric_value_numeric, unit_id) VALUES
(7, 'poses_held', 24, 12),
(7, 'balance_time', 180, 1),

(8, 'poses_held', 18, 12),
(8, 'flexibility_score', 8.5, 20),

(9, 'poses_held', 32, 12),
(9, 'balance_time', 210, 1);

-- Alex's music practice metrics
INSERT INTO activity_metric (session_id, metric_name, metric_value_text) VALUES
(11, 'practice_notes', 'Worked on Travis picking pattern, getting smoother'),
(11, 'pieces_practiced', 3);

INSERT INTO activity_metric (session_id, metric_name, metric_value_text) VALUES
(12, 'medium', 'Oil on canvas'),
(12, 'canvas_size', '24x36 inches');

-- ============================================================================
-- Personal Records
-- ============================================================================

INSERT INTO personal_record (user_id, activity_subtype_id, record_type, record_value,
    unit_id, session_id, exercise_id, previous_record_value, achieved_at, notes) VALUES
-- John's PRs
(1, 2, 'max_weight', 215, 2, 1, 1, 205, '2025-01-06 07:00:00', 'New bench press PR!'),
(1, 1, 'max_weight', 245, 2, 2, 5, 225, '2025-01-08 07:00:00', 'Squat PR with great form'),
(1, 3, 'max_weight', 365, 2, 3, 8, 345, '2025-01-10 07:00:00', 'Deadlift PR - huge milestone!');

-- Sarah's running PRs
INSERT INTO personal_record (user_id, activity_subtype_id, record_type, record_value,
    session_id, achieved_at, notes)
SELECT 2, NULL, 'best_time', 5.0, 5, '2025-01-08 07:00:00', 'Best 5K pace ever';

-- ============================================================================
-- User Goals
-- ============================================================================

INSERT INTO user_goal (user_id, goal_type_id, activity_type_id, title, description,
    target_value, target_unit_id, current_value, start_date, target_date, frequency_per_week, is_active) VALUES
-- John's goals
(1, 1, 1, 'Train 4 times per week', 'Consistent strength training schedule',
    NULL, NULL, NULL, '2025-01-01', '2025-12-31', 4, TRUE),
(1, 2, NULL, 'Bench press 225 lbs', 'Achieve 2-plate bench press',
    225, 2, 215, '2025-01-01', '2025-06-30', NULL, TRUE),
(1, 5, NULL, 'Lose 15 pounds', 'Get down to 185 lbs',
    185, 2, 200, '2025-01-01', '2025-06-30', NULL, TRUE),

-- Sarah's goals
(2, 1, 2, 'Run 5 days per week', 'Build running consistency',
    NULL, NULL, NULL, '2025-01-01', '2025-12-31', 5, TRUE),
(2, 2, 2, 'Run a sub-45 minute 10K', 'Improve 10K time',
    45, 7, 52, '2025-01-01', '2025-06-30', NULL, TRUE),
(2, 4, 2, 'Run 500 miles this year', 'Total annual mileage goal',
    500, 2, 15.3, '2025-01-01', '2025-12-31', NULL, TRUE),

-- Mike's goals
(3, 1, 5, 'Daily yoga practice', 'Establish daily yoga habit',
    NULL, NULL, NULL, '2025-01-01', '2025-12-31', 7, TRUE),
(3, 3, 5, '100-day yoga streak', 'Build 100 consecutive days of practice',
    100, 12, 3, '2025-01-06', '2025-04-15', NULL, TRUE);

-- ============================================================================
-- Goal Milestones
-- ============================================================================

INSERT INTO goal_milestone (goal_id, title, target_value, is_achieved, achieved_at) VALUES
-- John's bench press goal milestones
(2, 'Bench 205 lbs', 205, TRUE, '2024-12-15 07:00:00'),
(2, 'Bench 215 lbs', 215, TRUE, '2025-01-06 07:00:00'),
(2, 'Bench 225 lbs', 225, FALSE, NULL),

-- Sarah's 10K goal milestones
(5, 'Sub-52 minutes', 52, TRUE, '2024-11-01 08:00:00'),
(5, 'Sub-50 minutes', 50, FALSE, NULL),
(5, 'Sub-47 minutes', 47, FALSE, NULL),
(5, 'Sub-45 minutes', 45, FALSE, NULL);

-- ============================================================================
-- Body Metrics
-- ============================================================================

INSERT INTO user_body_metric (user_id, metric_type_id, value, unit_id, measured_at, notes) VALUES
-- John's body metrics
(1, 1, 200.5, 2, '2025-01-01 07:00:00', 'Starting weight'),
(1, 1, 199.2, 2, '2025-01-08 07:00:00', 'Down a bit'),
(1, 2, 18.5, 20, '2025-01-01 07:00:00', 'Starting body fat %'),
(1, 4, 42, 23, '2025-01-01 07:00:00', 'Chest measurement'),
(1, 5, 34, 23, '2025-01-01 07:00:00', 'Waist measurement'),

-- Sarah's body metrics
(2, 1, 58.5, 1, '2025-01-01 06:30:00', 'Maintaining weight'),
(2, 1, 58.3, 1, '2025-01-08 06:30:00', 'Slight decrease'),
(2, 10, 52, 12, '2025-01-01 06:30:00', 'Resting heart rate'),

-- Mike's body metrics
(3, 1, 72.0, 1, '2025-01-01 07:00:00', 'Current weight'),
(3, 10, 58, 12, '2025-01-01 07:00:00', 'Resting heart rate');

-- ============================================================================
-- Workout Programs
-- ============================================================================

INSERT INTO workout_program (creator_id, name, description, difficulty_level, duration_weeks,
    sessions_per_week, category_id, is_public, is_official, tags) VALUES
(NULL, 'Starting Strength', 'Classic beginner barbell program focusing on compound lifts',
    'beginner', 12, 3, 1, TRUE, TRUE, ARRAY['strength', 'barbell', 'compound']),
(NULL, 'Couch to 5K', 'Beginner running program to build up to 5K distance',
    'beginner', 9, 3, 1, TRUE, TRUE, ARRAY['running', 'cardio', 'beginner']),
(NULL, '30-Day Yoga Challenge', 'Daily yoga practice for flexibility and mindfulness',
    'beginner', 4, 7, 1, TRUE, TRUE, ARRAY['yoga', 'flexibility', 'mindfulness']),
(1, 'John''s Upper/Lower Split', 'Custom 4-day upper/lower body split',
    'intermediate', 8, 4, 1, FALSE, FALSE, ARRAY['strength', 'split', 'hypertrophy']);

-- Program session templates for Starting Strength
INSERT INTO program_session_template (program_id, week_number, day_number, session_name,
    description, activity_type_id, estimated_duration_minutes) VALUES
(1, 1, 1, 'Workout A', 'Squat, Bench Press, Deadlift', 1, 60),
(1, 1, 3, 'Workout B', 'Squat, Press, Deadlift', 1, 60),
(1, 1, 5, 'Workout A', 'Squat, Bench Press, Deadlift', 1, 60);

-- Program exercises for Workout A
INSERT INTO program_exercise_template (session_template_id, activity_subtype_id, exercise_order,
    target_sets, target_reps, rest_seconds, notes) VALUES
(1, 1, 1, 3, 5, 180, 'Work up to heavy set of 5'),
(1, 2, 2, 3, 5, 180, 'Linear progression'),
(1, 3, 3, 1, 5, 300, 'Heavy single set');

-- ============================================================================
-- User Program Enrollments
-- ============================================================================

INSERT INTO user_program_enrollment (user_id, program_id, start_date, current_week, current_day, is_active) VALUES
(1, 1, '2025-01-01', 2, 1, TRUE),
(2, 2, '2025-01-01', 2, 2, TRUE),
(3, 3, 1, 1, 6, TRUE);

-- ============================================================================
-- Achievements Earned
-- ============================================================================

INSERT INTO user_achievement (user_id, achievement_type_id, earned_at, related_session_id, progress_value) VALUES
(1, 1, '2024-12-01 07:00:00', NULL, 1),
(1, 9, '2025-01-10 07:00:00', 3, 3),
(2, 1, '2024-11-15 07:00:00', NULL, 1),
(3, 1, '2024-10-20 08:00:00', NULL, 1),
(3, 2, '2025-01-12 08:00:00', NULL, 7),
(4, 1, '2024-09-01 17:00:00', NULL, 1),
(5, 1, '2024-12-15 20:00:00', NULL, 1);

-- ============================================================================
-- User Streaks
-- ============================================================================

INSERT INTO user_streak (user_id, activity_type_id, current_streak_days, longest_streak_days, last_activity_date) VALUES
(1, 1, 5, 14, '2025-01-10'),
(1, NULL, 5, 14, '2025-01-10'),
(2, 2, 7, 23, '2025-01-12'),
(2, NULL, 7, 23, '2025-01-12'),
(3, 5, 4, 12, '2025-01-09'),
(3, NULL, 4, 12, '2025-01-09'),
(4, 8, 2, 8, '2025-01-08'),
(5, 10, 2, 5, '2025-01-07');

-- ============================================================================
-- Social Relationships
-- ============================================================================

INSERT INTO user_relationship (follower_id, following_id) VALUES
(1, 2), -- John follows Sarah
(1, 4), -- John follows Emma
(2, 1), -- Sarah follows John
(2, 3), -- Sarah follows Mike
(2, 4), -- Sarah follows Emma
(3, 2), -- Mike follows Sarah
(4, 1), -- Emma follows John
(4, 2), -- Emma follows Sarah
(5, 1), -- Alex follows John
(5, 2); -- Alex follows Sarah

-- ============================================================================
-- Session Shares
-- ============================================================================

INSERT INTO session_share (session_id, shared_by_user_id, visibility, share_message) VALUES
(3, 1, 'public', 'New deadlift PR! 365 lbs!'),
(5, 2, 'friends', 'Great interval workout this morning'),
(10, 4, 'public', 'Crushed this CrossFit WOD'),
(7, 3, 'friends', 'Morning yoga flow to start the day right');

-- ============================================================================
-- Session Comments
-- ============================================================================

INSERT INTO session_comment (session_id, user_id, comment_text) VALUES
(3, 2, 'Amazing progress! Keep it up!'),
(3, 4, 'That''s awesome! Congrats on the PR!'),
(5, 1, 'Great pace! How are you maintaining that speed?'),
(10, 2, 'That workout looks brutal! Nice work!');

-- ============================================================================
-- Session Likes
-- ============================================================================

INSERT INTO session_like (session_id, user_id) VALUES
(3, 2), (3, 4), (3, 5),
(5, 1), (5, 3), (5, 4),
(7, 2), (7, 4),
(10, 1), (10, 2), (10, 3);

-- ============================================================================
-- Session Media
-- ============================================================================

INSERT INTO session_media (session_id, media_type, media_url, thumbnail_url, caption,
    is_progress_photo, is_form_check) VALUES
(3, 'video', 'https://example.com/videos/deadlift-pr.mp4', 'https://example.com/thumbs/deadlift-pr.jpg',
    'New PR deadlift form check', FALSE, TRUE),
(1, 'image', 'https://example.com/images/bench-setup.jpg', 'https://example.com/thumbs/bench-setup.jpg',
    'Bench press setup', FALSE, FALSE),
(7, 'image', 'https://example.com/images/yoga-studio.jpg', 'https://example.com/thumbs/yoga-studio.jpg',
    'Beautiful morning at the studio', FALSE, FALSE);

-- ============================================================================
-- Refresh Materialized Views
-- ============================================================================

REFRESH MATERIALIZED VIEW user_statistics;

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Count records in each table
DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '=== Data Loading Summary ===';
    FOR rec IN
        SELECT
            table_name,
            (SELECT COUNT(*) FROM information_schema.tables t
             WHERE t.table_name = s.table_name) as count
        FROM information_schema.tables s
        WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        ORDER BY table_name
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I', rec.table_name) INTO rec.count;
        RAISE NOTICE '% : % records', rec.table_name, rec.count;
    END LOOP;
END $$;

-- ============================================================================
-- END OF SEED DATA
-- ============================================================================
