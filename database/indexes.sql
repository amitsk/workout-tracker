CREATE INDEX idx_session_user_type_date ON activity_session(user_id, activity_type_id, started_at);
CREATE INDEX idx_metric_name_value ON activity_metric(metric_name, metric_value_numeric);
CREATE INDEX idx_session_started_date ON activity_session(DATE(started_at));