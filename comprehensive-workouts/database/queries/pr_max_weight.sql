-- PR: max working-set weight for Bench Press
-- Uses exercise_set (schema v2), not the EAV activity_metric table.
SELECT
    s.id AS session_id,
    s.started_at,
    st.name AS exercise,
    es.weight,
    u.symbol AS unit
FROM exercise_set es
JOIN activity_exercise ae ON ae.id = es.exercise_id
JOIN activity_session s ON s.id = ae.session_id
JOIN activity_subtype st ON st.id = ae.activity_subtype_id
LEFT JOIN unit u ON u.id = es.weight_unit_id
WHERE st.name = 'Bench Press'
  AND es.weight IS NOT NULL
  AND s.deleted_at IS NULL
ORDER BY es.weight DESC, s.started_at DESC
LIMIT 1;
