-- Sample data for the minimal Weight Training Workout Tracker.
-- Run after schema.sql. Password hashes are bcrypt placeholders, not real secrets.

-- Users
INSERT INTO users (name, email, password_hash) VALUES
('John Doe', 'john.doe@example.com', '$2b$10$dummy.hash.for.demo.purposes.only'),
('Jane Smith', 'jane.smith@example.com', '$2b$10$dummy.hash.for.demo.purposes.only'),
('Mike Johnson', 'mike.johnson@example.com', '$2b$10$dummy.hash.for.demo.purposes.only');

-- Shared exercise catalog
INSERT INTO workout_types (name, description) VALUES
('Bench Press', 'Chest exercise performed lying on a bench'),
('Squat', 'Lower body exercise targeting quadriceps and glutes'),
('Deadlift', 'Full body exercise focusing on posterior chain'),
('Overhead Press', 'Shoulder exercise performed standing'),
('Barbell Row', 'Back exercise performed with barbell'),
('Pull-ups', 'Bodyweight back exercise; log added load in weight when used'),
('Bicep Curl', 'Arm exercise targeting biceps'),
('Tricep Extension', 'Arm exercise targeting triceps');

-- Sessions (timestamptz: date and time)
INSERT INTO sessions (user_id, started_at, notes) VALUES
(1, '2025-11-01 18:00:00-05', 'Upper body workout'),
(1, '2025-11-03 18:30:00-05', 'Lower body workout'),
(1, '2025-11-05 17:45:00-05', 'Full body workout'),
(2, '2025-11-02 09:00:00+00', 'Push day'),
(2, '2025-11-04 09:15:00+00', 'Pull day'),
(3, '2025-11-01 19:00:00+00', 'First workout of the week'),
(3, '2025-11-03 19:00:00+00', 'Feeling strong today');

-- Workouts (exercise blocks). IDs 1–20 follow insert order.
INSERT INTO workouts (session_id, workout_type_id, display_order, notes) VALUES
-- John's upper body (session 1)
(1, 1, 0, NULL),  -- 1 Bench Press
(1, 4, 1, NULL),  -- 2 Overhead Press
(1, 5, 2, NULL),  -- 3 Barbell Row
(1, 7, 3, NULL),  -- 4 Bicep Curl
-- John's lower body (session 2)
(2, 2, 0, NULL),  -- 5 Squat
(2, 3, 1, NULL),  -- 6 Deadlift
-- John's full body (session 3)
(3, 1, 0, NULL),  -- 7 Bench Press
(3, 2, 1, NULL),  -- 8 Squat
(3, 6, 2, 'Bodyweight'), -- 9 Pull-ups
-- Jane's push (session 4)
(4, 1, 0, NULL),  -- 10 Bench Press
(4, 4, 1, NULL),  -- 11 Overhead Press
(4, 8, 2, NULL),  -- 12 Tricep Extension
-- Jane's pull (session 5)
(5, 5, 0, NULL),  -- 13 Barbell Row
(5, 6, 1, NULL),  -- 14 Pull-ups
(5, 7, 2, NULL),  -- 15 Bicep Curl
-- Mike's first (session 6)
(6, 1, 0, NULL),  -- 16 Bench Press
(6, 2, 1, NULL),  -- 17 Squat
(6, 3, 2, NULL),  -- 18 Deadlift
-- Mike's second (session 7)
(7, 4, 0, NULL),  -- 19 Overhead Press
(7, 5, 1, NULL),  -- 20 Barbell Row
(7, 6, 2, NULL);  -- 21 Pull-ups

-- Sets. John's bench uses a small progression so per-set logging is visible.
INSERT INTO workout_sets (workout_id, set_number, reps, weight, weight_unit) VALUES
-- 1 Bench Press (John, lbs) — not a flat 4×8
(1, 1, 8, 175.00, 'lbs'),
(1, 2, 8, 185.00, 'lbs'),
(1, 3, 8, 185.00, 'lbs'),
(1, 4, 6, 185.00, 'lbs'),
-- 2 Overhead Press
(2, 1, 10, 135.00, 'lbs'),
(2, 2, 10, 135.00, 'lbs'),
(2, 3, 8, 135.00, 'lbs'),
-- 3 Barbell Row
(3, 1, 12, 155.00, 'lbs'),
(3, 2, 12, 155.00, 'lbs'),
(3, 3, 12, 155.00, 'lbs'),
-- 4 Bicep Curl
(4, 1, 12, 45.00, 'lbs'),
(4, 2, 12, 45.00, 'lbs'),
(4, 3, 12, 45.00, 'lbs'),
-- 5 Squat
(5, 1, 6, 275.00, 'lbs'),
(5, 2, 6, 275.00, 'lbs'),
(5, 3, 6, 275.00, 'lbs'),
(5, 4, 6, 275.00, 'lbs'),
-- 6 Deadlift
(6, 1, 8, 315.00, 'lbs'),
(6, 2, 8, 315.00, 'lbs'),
(6, 3, 8, 315.00, 'lbs'),
-- 7 Bench Press (full body)
(7, 1, 10, 165.00, 'lbs'),
(7, 2, 10, 165.00, 'lbs'),
(7, 3, 10, 165.00, 'lbs'),
-- 8 Squat (full body)
(8, 1, 8, 245.00, 'lbs'),
(8, 2, 8, 245.00, 'lbs'),
(8, 3, 8, 245.00, 'lbs'),
-- 9 Pull-ups (bodyweight → NULL weight)
(9, 1, 8, NULL, 'lbs'),
(9, 2, 8, NULL, 'lbs'),
(9, 3, 6, NULL, 'lbs'),
-- 10 Jane Bench Press (kg)
(10, 1, 8, 95.00, 'kg'),
(10, 2, 8, 95.00, 'kg'),
(10, 3, 8, 95.00, 'kg'),
(10, 4, 8, 95.00, 'kg'),
-- 11 Overhead Press
(11, 1, 10, 50.00, 'kg'),
(11, 2, 10, 50.00, 'kg'),
(11, 3, 10, 50.00, 'kg'),
-- 12 Tricep Extension
(12, 1, 12, 25.00, 'kg'),
(12, 2, 12, 25.00, 'kg'),
(12, 3, 12, 25.00, 'kg'),
-- 13 Barbell Row
(13, 1, 12, 60.00, 'kg'),
(13, 2, 12, 60.00, 'kg'),
(13, 3, 12, 60.00, 'kg'),
-- 14 Pull-ups
(14, 1, 10, NULL, 'kg'),
(14, 2, 10, NULL, 'kg'),
(14, 3, 8, NULL, 'kg'),
-- 15 Bicep Curl
(15, 1, 15, 20.00, 'kg'),
(15, 2, 15, 20.00, 'kg'),
(15, 3, 15, 20.00, 'kg'),
-- 16 Mike Bench Press
(16, 1, 10, 80.00, 'kg'),
(16, 2, 10, 80.00, 'kg'),
(16, 3, 10, 80.00, 'kg'),
-- 17 Squat
(17, 1, 8, 100.00, 'kg'),
(17, 2, 8, 100.00, 'kg'),
(17, 3, 8, 100.00, 'kg'),
-- 18 Deadlift
(18, 1, 5, 120.00, 'kg'),
(18, 2, 5, 120.00, 'kg'),
(18, 3, 5, 120.00, 'kg'),
-- 19 Overhead Press
(19, 1, 10, 60.00, 'kg'),
(19, 2, 10, 60.00, 'kg'),
(19, 3, 10, 60.00, 'kg'),
-- 20 Barbell Row
(20, 1, 12, 70.00, 'kg'),
(20, 2, 12, 70.00, 'kg'),
(20, 3, 12, 70.00, 'kg'),
-- 21 Pull-ups
(21, 1, 6, NULL, 'kg'),
(21, 2, 6, NULL, 'kg'),
(21, 3, 6, NULL, 'kg');
