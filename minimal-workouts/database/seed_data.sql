-- Sample data for Weight Training Workout Tracker
-- Run after schema.sql

-- Insert sample users
INSERT INTO users (name, email, password_hash) VALUES
('John Doe', 'john.doe@example.com', '$2b$10$dummy.hash.for.demo.purposes.only'),
('Jane Smith', 'jane.smith@example.com', '$2b$10$dummy.hash.for.demo.purposes.only'),
('Mike Johnson', 'mike.johnson@example.com', '$2b$10$dummy.hash.for.demo.purposes.only');

-- Insert sample workout types
INSERT INTO workout_types (name, description) VALUES
('Bench Press', 'Chest exercise performed lying on a bench'),
('Squat', 'Lower body exercise targeting quadriceps and glutes'),
('Deadlift', 'Full body exercise focusing on posterior chain'),
('Overhead Press', 'Shoulder exercise performed standing'),
('Barbell Row', 'Back exercise performed with barbell'),
('Pull-ups', 'Bodyweight back exercise'),
('Bicep Curl', 'Arm exercise targeting biceps'),
('Tricep Extension', 'Arm exercise targeting triceps');

-- Insert sample sessions
INSERT INTO sessions (user_id, session_date, notes) VALUES
(1, '2025-11-01', 'Upper body workout'),
(1, '2025-11-03', 'Lower body workout'),
(1, '2025-11-05', 'Full body workout'),
(2, '2025-11-02', 'Push day'),
(2, '2025-11-04', 'Pull day'),
(3, '2025-11-01', 'First workout of the week'),
(3, '2025-11-03', 'Feeling strong today');

-- Insert sample workouts
INSERT INTO workouts (session_id, workout_type_id, sets, reps, weight, weight_unit) VALUES
-- John's upper body session (session_id 1)
(1, 1, 4, 8, 185.00, 'lbs'), -- Bench Press
(1, 4, 3, 10, 135.00, 'lbs'), -- Overhead Press
(1, 5, 3, 12, 155.00, 'lbs'), -- Barbell Row
(1, 7, 3, 12, 45.00, 'lbs'), -- Bicep Curl

-- John's lower body session (session_id 2)
(2, 2, 4, 6, 275.00, 'lbs'), -- Squat
(2, 3, 3, 8, 315.00, 'lbs'), -- Deadlift

-- John's full body session (session_id 3)
(3, 1, 3, 10, 165.00, 'lbs'), -- Bench Press
(3, 2, 3, 8, 245.00, 'lbs'), -- Squat
(3, 6, 3, 8, 0.00, 'bodyweight'), -- Pull-ups

-- Jane's push day (session_id 4)
(4, 1, 4, 8, 95.00, 'kg'), -- Bench Press
(4, 4, 3, 10, 50.00, 'kg'), -- Overhead Press
(4, 8, 3, 12, 25.00, 'kg'), -- Tricep Extension

-- Jane's pull day (session_id 5)
(5, 5, 3, 12, 60.00, 'kg'), -- Barbell Row
(5, 6, 3, 10, 0.00, 'bodyweight'), -- Pull-ups
(5, 7, 3, 15, 20.00, 'kg'), -- Bicep Curl

-- Mike's first workout (session_id 6)
(6, 1, 3, 10, 80.00, 'kg'), -- Bench Press
(6, 2, 3, 8, 100.00, 'kg'), -- Squat
(6, 3, 3, 5, 120.00, 'kg'), -- Deadlift

-- Mike's second workout (session_id 7)
(7, 4, 3, 10, 60.00, 'kg'), -- Overhead Press
(7, 5, 3, 12, 70.00, 'kg'), -- Barbell Row
(7, 6, 3, 6, 0.00, 'bodyweight'); -- Pull-ups