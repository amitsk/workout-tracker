-- PR: Max weight for Bench Press
SELECT 
    s.id, s.started_at, m1.metric_value_numeric AS weight_kg
FROM activity_session s
JOIN activity_metric m1 ON s.id = m1.session_id AND m1.metric_name = 'weight'
JOIN activity_subtype st ON s.activity_subtype_id = st.id
WHERE st.name = 'Bench Press'
  AND m1.unit_id = (SELECT id FROM unit WHERE name = 'kilograms')
ORDER BY m1.metric_value_numeric DESC
LIMIT 1;