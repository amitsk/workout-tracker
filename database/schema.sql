-- database/schema.sql
CREATE TABLE activity_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE activity_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id INT REFERENCES activity_category(id) ON DELETE SET NULL,
    is_physical BOOLEAN DEFAULT TRUE,
    has_duration BOOLEAN DEFAULT TRUE,
    has_intensity BOOLEAN DEFAULT FALSE,
    description TEXT,
    icon_url VARCHAR(255),
    UNIQUE(name)
);

CREATE TABLE activity_subtype (
    id SERIAL PRIMARY KEY,
    activity_type_id INT NOT NULL REFERENCES activity_type(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    default_sets INT,
    default_reps INT,
    default_weight DECIMAL(6,2),
    default_weight_unit VARCHAR(10) DEFAULT 'kg',
    UNIQUE(activity_type_id, name)
);

CREATE TABLE unit (
    id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
    symbol VARCHAR(10),
    type VARCHAR(20)
);

CREATE TABLE app_user (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE activity_session (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES app_user(id) ON DELETE CASCADE,
    activity_type_id INT NOT NULL REFERENCES activity_type(id),
    activity_subtype_id INT REFERENCES activity_subtype(id) ON DELETE SET NULL,
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    duration_minutes INT GENERATED ALWAYS AS (
        CASE WHEN ended_at IS NOT NULL THEN EXTRACT(EPOCH FROM (ended_at - started_at))/60 ELSE NULL END
    ) STORED,
    location VARCHAR(100),
    mood_before VARCHAR(50),
    mood_after VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE activity_metric (
    id SERIAL PRIMARY KEY,
    session_id INT NOT NULL REFERENCES activity_session(id) ON DELETE CASCADE,
    metric_name VARCHAR(50) NOT NULL,
    metric_value_numeric DECIMAL(10,3),
    metric_value_text TEXT,
    unit_id INT REFERENCES unit(id),
    CONSTRAINT chk_one_value CHECK (
        (metric_value_numeric IS NOT NULL AND metric_value_text IS NULL) OR
        (metric_value_numeric IS NULL AND metric_value_text IS NOT NULL) OR
        (metric_value_numeric IS NULL AND metric_value_text IS NULL)
    )
);

CREATE TABLE activity_type_metric_template (
    id SERIAL PRIMARY KEY,
    activity_type_id INT NOT NULL REFERENCES activity_type(id) ON DELETE CASCADE,
    metric_name VARCHAR(50) NOT NULL,
    unit_id INT REFERENCES unit(id),
    is_required BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    UNIQUE(activity_type_id, metric_name)
);