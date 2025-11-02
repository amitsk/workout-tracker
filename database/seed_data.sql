-- database/seed_data.sql
INSERT INTO activity_category (name) VALUES ('Physical'), ('Cognitive'), ('Creative');

INSERT INTO unit (name, symbol, type) VALUES
('kilograms', 'kg', 'weight'), ('pounds', 'lbs', 'weight'),
('minutes', 'min', 'time'), ('kilometers', 'km', 'distance'),
('beats per minute', 'bpm', 'intensity'), ('count', '', 'count'),
('pages', 'pages', 'count');

INSERT INTO activity_type (name, category_id, has_duration, has_intensity) VALUES
('Running', 1, TRUE, TRUE), ('Weights', 1, TRUE, FALSE),
('Yoga', 1, TRUE, FALSE), ('Chess', 2, TRUE, FALSE), ('Painting', 3, TRUE, FALSE);

INSERT INTO activity_subtype (activity_type_id, name, default_sets, default_reps) VALUES
((SELECT id FROM activity_type WHERE name='Weights'), 'Bench Press', 3, 10),
((SELECT id FROM activity_type WHERE name='Weights'), 'Squats', 4, 8);

INSERT INTO activity_type_metric_template (activity_type_id, metric_name, unit_id, is_required) VALUES
((SELECT id FROM activity_type WHERE name='Weights'), 'sets', (SELECT id FROM unit WHERE name='count'), TRUE),
((SELECT id FROM activity_type WHERE name='Weights'), 'reps', (SELECT id FROM unit WHERE name='count'), TRUE),
((SELECT id FROM activity_type WHERE name='Weights'), 'weight', (SELECT id FROM unit WHERE name='kilograms'), TRUE);