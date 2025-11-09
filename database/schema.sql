-- ============================================================================
-- Activity Tracker Database Schema
-- Version: 2.0
-- Database: PostgreSQL 14+
-- ============================================================================

-- Drop existing tables (in reverse order of dependencies)
DROP TABLE IF EXISTS session_like CASCADE;
DROP TABLE IF EXISTS session_comment CASCADE;
DROP TABLE IF EXISTS session_share CASCADE;
DROP TABLE IF EXISTS user_relationship CASCADE;
DROP TABLE IF EXISTS user_streak CASCADE;
DROP TABLE IF EXISTS user_achievement CASCADE;
DROP TABLE IF EXISTS achievement_type CASCADE;
DROP TABLE IF EXISTS user_program_enrollment CASCADE;
DROP TABLE IF EXISTS program_exercise_template CASCADE;
DROP TABLE IF EXISTS program_session_template CASCADE;
DROP TABLE IF EXISTS workout_program CASCADE;
DROP TABLE IF EXISTS user_body_metric CASCADE;
DROP TABLE IF EXISTS body_metric_type CASCADE;
DROP TABLE IF EXISTS personal_record CASCADE;
DROP TABLE IF EXISTS goal_milestone CASCADE;
DROP TABLE IF EXISTS user_goal CASCADE;
DROP TABLE IF EXISTS goal_type CASCADE;
DROP TABLE IF EXISTS session_media CASCADE;
DROP TABLE IF EXISTS activity_type_metric_template CASCADE;
DROP TABLE IF EXISTS activity_metric CASCADE;
DROP TABLE IF EXISTS exercise_set CASCADE;
DROP TABLE IF EXISTS activity_exercise CASCADE;
DROP TABLE IF EXISTS activity_session CASCADE;
DROP TABLE IF EXISTS activity_subtype CASCADE;
DROP TABLE IF EXISTS activity_type CASCADE;
DROP TABLE IF EXISTS activity_category CASCADE;
DROP TABLE IF EXISTS unit CASCADE;
DROP TABLE IF EXISTS app_user CASCADE;

-- Drop materialized views
DROP MATERIALIZED VIEW IF EXISTS user_statistics CASCADE;

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- User Management
-- ----------------------------------------------------------------------------

CREATE TABLE app_user (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url VARCHAR(500),
    timezone VARCHAR(50) DEFAULT 'UTC',
    measurement_preference VARCHAR(10) DEFAULT 'metric',
    weight_unit_id INT,
    distance_unit_id INT,
    date_format VARCHAR(20) DEFAULT 'YYYY-MM-DD',
    language VARCHAR(10) DEFAULT 'en',
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP,

    CONSTRAINT chk_user_measurement CHECK (measurement_preference IN ('metric', 'imperial')),
    CONSTRAINT chk_user_username_length CHECK (LENGTH(username) >= 3),
    CONSTRAINT chk_user_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- ----------------------------------------------------------------------------
-- Units of Measurement
-- ----------------------------------------------------------------------------

CREATE TABLE unit (
    id SERIAL PRIMARY KEY,
    name VARCHAR(20) UNIQUE NOT NULL,
    symbol VARCHAR(10),
    type VARCHAR(20),
    conversion_factor DECIMAL(12,6),
    is_base_unit BOOLEAN DEFAULT FALSE
);

-- Add foreign keys for app_user units
ALTER TABLE app_user
    ADD CONSTRAINT fk_user_weight_unit FOREIGN KEY (weight_unit_id) REFERENCES unit(id),
    ADD CONSTRAINT fk_user_distance_unit FOREIGN KEY (distance_unit_id) REFERENCES unit(id);

-- ----------------------------------------------------------------------------
-- Activity Hierarchy
-- ----------------------------------------------------------------------------

CREATE TABLE activity_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    icon_name VARCHAR(50),
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE activity_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    category_id INT NOT NULL,
    is_physical BOOLEAN DEFAULT TRUE,
    has_duration BOOLEAN DEFAULT TRUE,
    has_intensity BOOLEAN DEFAULT FALSE,
    description TEXT,
    icon_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_type_category FOREIGN KEY (category_id) REFERENCES activity_category(id) ON DELETE CASCADE
);

CREATE TABLE activity_subtype (
    id SERIAL PRIMARY KEY,
    activity_type_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    default_sets INT,
    default_reps INT,
    default_weight DECIMAL(6,2),
    default_weight_unit VARCHAR(10) DEFAULT 'kg',
    muscle_groups TEXT[],
    difficulty_level VARCHAR(20),
    equipment_needed TEXT[],
    instructions TEXT,
    video_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_subtype_type FOREIGN KEY (activity_type_id) REFERENCES activity_type(id) ON DELETE CASCADE,
    CONSTRAINT uq_subtype_name UNIQUE (activity_type_id, name),
    CONSTRAINT chk_subtype_difficulty CHECK (difficulty_level IS NULL OR difficulty_level IN ('beginner', 'intermediate', 'advanced'))
);

-- ----------------------------------------------------------------------------
-- Activity Sessions
-- ----------------------------------------------------------------------------

CREATE TABLE activity_session (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    activity_type_id INT NOT NULL,
    activity_subtype_id INT,
    session_name VARCHAR(200),
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    duration_minutes INT GENERATED ALWAYS AS (
        CASE WHEN ended_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM (ended_at - started_at))/60
        ELSE NULL END
    ) STORED,
    location VARCHAR(100),
    weather VARCHAR(100),
    mood_before VARCHAR(50),
    mood_after VARCHAR(50),
    energy_level INT,
    rating INT,
    perceived_exertion INT,
    injuries_noted TEXT,
    notes TEXT,
    total_volume DECIMAL(12,2),
    estimated_calories DECIMAL(8,2),
    is_personal_record BOOLEAN DEFAULT FALSE,
    is_template BOOLEAN DEFAULT FALSE,
    template_name VARCHAR(200),
    parent_session_id INT,
    search_vector TSVECTOR,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP,

    CONSTRAINT fk_session_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_session_type FOREIGN KEY (activity_type_id) REFERENCES activity_type(id) ON DELETE RESTRICT,
    CONSTRAINT fk_session_subtype FOREIGN KEY (activity_subtype_id) REFERENCES activity_subtype(id) ON DELETE SET NULL,
    CONSTRAINT fk_session_parent FOREIGN KEY (parent_session_id) REFERENCES activity_session(id) ON DELETE SET NULL,
    CONSTRAINT chk_session_end_time CHECK (ended_at IS NULL OR ended_at >= started_at),
    CONSTRAINT chk_session_rating CHECK (rating IS NULL OR (rating >= 1 AND rating <= 10)),
    CONSTRAINT chk_session_energy CHECK (energy_level IS NULL OR (energy_level >= 1 AND energy_level <= 10)),
    CONSTRAINT chk_session_exertion CHECK (perceived_exertion IS NULL OR (perceived_exertion >= 1 AND perceived_exertion <= 10))
);

-- ----------------------------------------------------------------------------
-- Exercise & Set Tracking (Strength Training)
-- ----------------------------------------------------------------------------

CREATE TABLE activity_exercise (
    id SERIAL PRIMARY KEY,
    session_id INT NOT NULL,
    activity_subtype_id INT,
    exercise_order INT NOT NULL,
    superset_group INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_exercise_session FOREIGN KEY (session_id) REFERENCES activity_session(id) ON DELETE CASCADE,
    CONSTRAINT fk_exercise_subtype FOREIGN KEY (activity_subtype_id) REFERENCES activity_subtype(id) ON DELETE SET NULL
);

CREATE TABLE exercise_set (
    id SERIAL PRIMARY KEY,
    exercise_id INT NOT NULL,
    set_number INT NOT NULL,
    reps INT,
    weight DECIMAL(8,2),
    weight_unit_id INT,
    rest_seconds INT,
    rpe INT,
    tempo VARCHAR(20),
    is_warmup BOOLEAN DEFAULT FALSE,
    is_failure BOOLEAN DEFAULT FALSE,
    is_drop_set BOOLEAN DEFAULT FALSE,
    form_video_url VARCHAR(500),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_set_exercise FOREIGN KEY (exercise_id) REFERENCES activity_exercise(id) ON DELETE CASCADE,
    CONSTRAINT fk_set_unit FOREIGN KEY (weight_unit_id) REFERENCES unit(id),
    CONSTRAINT uq_set_number UNIQUE (exercise_id, set_number),
    CONSTRAINT chk_set_rpe CHECK (rpe IS NULL OR (rpe >= 1 AND rpe <= 10)),
    CONSTRAINT chk_set_reps CHECK (reps IS NULL OR reps > 0),
    CONSTRAINT chk_set_weight CHECK (weight IS NULL OR weight >= 0)
);

-- ----------------------------------------------------------------------------
-- Flexible Metrics (EAV Pattern)
-- ----------------------------------------------------------------------------

CREATE TABLE activity_metric (
    id SERIAL PRIMARY KEY,
    session_id INT NOT NULL,
    metric_name VARCHAR(50) NOT NULL,
    metric_value_numeric DECIMAL(10,3),
    metric_value_text TEXT,
    unit_id INT,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_metric_session FOREIGN KEY (session_id) REFERENCES activity_session(id) ON DELETE CASCADE,
    CONSTRAINT fk_metric_unit FOREIGN KEY (unit_id) REFERENCES unit(id),
    CONSTRAINT chk_metric_value CHECK (
        (metric_value_numeric IS NOT NULL AND metric_value_text IS NULL) OR
        (metric_value_numeric IS NULL AND metric_value_text IS NOT NULL)
    ),
    CONSTRAINT chk_metric_numeric CHECK (metric_value_numeric IS NULL OR metric_value_numeric >= 0)
);

CREATE TABLE activity_type_metric_template (
    id SERIAL PRIMARY KEY,
    activity_type_id INT NOT NULL,
    metric_name VARCHAR(50) NOT NULL,
    unit_id INT,
    is_required BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    input_type VARCHAR(20),
    validation_rule TEXT,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_template_type FOREIGN KEY (activity_type_id) REFERENCES activity_type(id) ON DELETE CASCADE,
    CONSTRAINT fk_template_unit FOREIGN KEY (unit_id) REFERENCES unit(id),
    CONSTRAINT uq_template_metric UNIQUE (activity_type_id, metric_name),
    CONSTRAINT chk_template_input CHECK (input_type IS NULL OR input_type IN ('number', 'text', 'duration'))
);

-- ----------------------------------------------------------------------------
-- Media Attachments
-- ----------------------------------------------------------------------------

CREATE TABLE session_media (
    id SERIAL PRIMARY KEY,
    session_id INT,
    exercise_id INT,
    media_type VARCHAR(20) NOT NULL,
    media_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    file_size_bytes BIGINT,
    duration_seconds INT,
    caption TEXT,
    tags TEXT[],
    is_progress_photo BOOLEAN DEFAULT FALSE,
    is_form_check BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_media_session FOREIGN KEY (session_id) REFERENCES activity_session(id) ON DELETE CASCADE,
    CONSTRAINT fk_media_exercise FOREIGN KEY (exercise_id) REFERENCES activity_exercise(id) ON DELETE CASCADE,
    CONSTRAINT chk_media_type CHECK (media_type IN ('image', 'video', 'audio')),
    CONSTRAINT chk_media_parent CHECK (
        (session_id IS NOT NULL AND exercise_id IS NULL) OR
        (session_id IS NULL AND exercise_id IS NOT NULL)
    )
);

-- ----------------------------------------------------------------------------
-- Goal Management
-- ----------------------------------------------------------------------------

CREATE TABLE goal_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    icon_name VARCHAR(50)
);

CREATE TABLE user_goal (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    goal_type_id INT NOT NULL,
    activity_type_id INT,
    activity_subtype_id INT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    target_value DECIMAL(10,2),
    target_unit_id INT,
    current_value DECIMAL(10,2),
    start_date DATE NOT NULL,
    target_date DATE,
    frequency_per_week INT,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_goal_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_type FOREIGN KEY (goal_type_id) REFERENCES goal_type(id) ON DELETE RESTRICT,
    CONSTRAINT fk_goal_activity_type FOREIGN KEY (activity_type_id) REFERENCES activity_type(id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_subtype FOREIGN KEY (activity_subtype_id) REFERENCES activity_subtype(id) ON DELETE CASCADE,
    CONSTRAINT fk_goal_unit FOREIGN KEY (target_unit_id) REFERENCES unit(id)
);

CREATE TABLE goal_milestone (
    id SERIAL PRIMARY KEY,
    goal_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    target_value DECIMAL(10,2),
    achieved_at TIMESTAMP,
    is_achieved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_milestone_goal FOREIGN KEY (goal_id) REFERENCES user_goal(id) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- Personal Records
-- ----------------------------------------------------------------------------

CREATE TABLE personal_record (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    activity_subtype_id INT NOT NULL,
    record_type VARCHAR(30) NOT NULL,
    record_value DECIMAL(10,2) NOT NULL,
    unit_id INT,
    session_id INT NOT NULL,
    exercise_id INT,
    previous_record_value DECIMAL(10,2),
    achieved_at TIMESTAMP NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_pr_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_pr_subtype FOREIGN KEY (activity_subtype_id) REFERENCES activity_subtype(id) ON DELETE CASCADE,
    CONSTRAINT fk_pr_unit FOREIGN KEY (unit_id) REFERENCES unit(id),
    CONSTRAINT fk_pr_session FOREIGN KEY (session_id) REFERENCES activity_session(id) ON DELETE CASCADE,
    CONSTRAINT fk_pr_exercise FOREIGN KEY (exercise_id) REFERENCES activity_exercise(id) ON DELETE CASCADE,
    CONSTRAINT uq_pr_user_exercise_type UNIQUE (user_id, activity_subtype_id, record_type),
    CONSTRAINT chk_pr_type CHECK (record_type IN ('1rm', 'max_weight', 'max_reps', 'max_volume', 'max_distance', 'best_time'))
);

-- ----------------------------------------------------------------------------
-- Body Metrics
-- ----------------------------------------------------------------------------

CREATE TABLE body_metric_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(30),
    default_unit_id INT,
    description TEXT,

    CONSTRAINT fk_body_metric_unit FOREIGN KEY (default_unit_id) REFERENCES unit(id),
    CONSTRAINT chk_body_metric_category CHECK (category IS NULL OR category IN ('weight', 'composition', 'measurement', 'vital'))
);

CREATE TABLE user_body_metric (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    metric_type_id INT NOT NULL,
    value DECIMAL(8,2) NOT NULL,
    unit_id INT NOT NULL,
    measured_at TIMESTAMP NOT NULL DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_body_metric_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_body_metric_type FOREIGN KEY (metric_type_id) REFERENCES body_metric_type(id) ON DELETE CASCADE,
    CONSTRAINT fk_body_metric_unit FOREIGN KEY (unit_id) REFERENCES unit(id)
);

-- ----------------------------------------------------------------------------
-- Workout Programs
-- ----------------------------------------------------------------------------

CREATE TABLE workout_program (
    id SERIAL PRIMARY KEY,
    creator_id INT,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    difficulty_level VARCHAR(20),
    duration_weeks INT,
    sessions_per_week INT,
    category_id INT,
    is_public BOOLEAN DEFAULT FALSE,
    is_official BOOLEAN DEFAULT FALSE,
    tags TEXT[],
    thumbnail_url VARCHAR(500),
    search_vector TSVECTOR,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP,

    CONSTRAINT fk_program_creator FOREIGN KEY (creator_id) REFERENCES app_user(id) ON DELETE SET NULL,
    CONSTRAINT fk_program_category FOREIGN KEY (category_id) REFERENCES activity_category(id) ON DELETE SET NULL,
    CONSTRAINT chk_program_difficulty CHECK (difficulty_level IS NULL OR difficulty_level IN ('beginner', 'intermediate', 'advanced'))
);

CREATE TABLE program_session_template (
    id SERIAL PRIMARY KEY,
    program_id INT NOT NULL,
    week_number INT NOT NULL,
    day_number INT NOT NULL,
    session_name VARCHAR(200),
    description TEXT,
    activity_type_id INT NOT NULL,
    estimated_duration_minutes INT,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_template_program FOREIGN KEY (program_id) REFERENCES workout_program(id) ON DELETE CASCADE,
    CONSTRAINT fk_template_activity_type FOREIGN KEY (activity_type_id) REFERENCES activity_type(id) ON DELETE RESTRICT
);

CREATE TABLE program_exercise_template (
    id SERIAL PRIMARY KEY,
    session_template_id INT NOT NULL,
    activity_subtype_id INT,
    exercise_order INT NOT NULL,
    target_sets INT,
    target_reps INT,
    target_weight_pct DECIMAL(5,2),
    rest_seconds INT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_exercise_template_session FOREIGN KEY (session_template_id) REFERENCES program_session_template(id) ON DELETE CASCADE,
    CONSTRAINT fk_exercise_template_subtype FOREIGN KEY (activity_subtype_id) REFERENCES activity_subtype(id) ON DELETE SET NULL
);

CREATE TABLE user_program_enrollment (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    program_id INT NOT NULL,
    start_date DATE NOT NULL,
    current_week INT DEFAULT 1,
    current_day INT DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_enrollment_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_enrollment_program FOREIGN KEY (program_id) REFERENCES workout_program(id) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- Gamification
-- ----------------------------------------------------------------------------

CREATE TABLE achievement_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    badge_icon_url VARCHAR(500),
    category VARCHAR(50),
    criteria_json JSONB,
    points INT DEFAULT 0,
    rarity VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT chk_achievement_rarity CHECK (rarity IS NULL OR rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary'))
);

CREATE TABLE user_achievement (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    achievement_type_id INT NOT NULL,
    earned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    related_session_id INT,
    progress_value DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_achievement_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_achievement_type FOREIGN KEY (achievement_type_id) REFERENCES achievement_type(id) ON DELETE CASCADE,
    CONSTRAINT fk_achievement_session FOREIGN KEY (related_session_id) REFERENCES activity_session(id) ON DELETE SET NULL,
    CONSTRAINT uq_user_achievement UNIQUE (user_id, achievement_type_id)
);

CREATE TABLE user_streak (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    activity_type_id INT,
    current_streak_days INT DEFAULT 0,
    longest_streak_days INT DEFAULT 0,
    last_activity_date DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_streak_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_streak_activity FOREIGN KEY (activity_type_id) REFERENCES activity_type(id) ON DELETE CASCADE,
    CONSTRAINT uq_user_streak UNIQUE (user_id, activity_type_id)
);

-- ----------------------------------------------------------------------------
-- Social Features
-- ----------------------------------------------------------------------------

CREATE TABLE user_relationship (
    id SERIAL PRIMARY KEY,
    follower_id INT NOT NULL,
    following_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_relationship_follower FOREIGN KEY (follower_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_relationship_following FOREIGN KEY (following_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT uq_relationship UNIQUE (follower_id, following_id),
    CONSTRAINT chk_no_self_follow CHECK (follower_id != following_id)
);

CREATE TABLE session_share (
    id SERIAL PRIMARY KEY,
    session_id INT NOT NULL,
    shared_by_user_id INT NOT NULL,
    visibility VARCHAR(20) DEFAULT 'friends',
    share_message TEXT,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_share_session FOREIGN KEY (session_id) REFERENCES activity_session(id) ON DELETE CASCADE,
    CONSTRAINT fk_share_user FOREIGN KEY (shared_by_user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT chk_share_visibility CHECK (visibility IN ('public', 'friends', 'private'))
);

CREATE TABLE session_comment (
    id SERIAL PRIMARY KEY,
    session_id INT NOT NULL,
    user_id INT NOT NULL,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP,

    CONSTRAINT fk_comment_session FOREIGN KEY (session_id) REFERENCES activity_session(id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE
);

CREATE TABLE session_like (
    id SERIAL PRIMARY KEY,
    session_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_like_session FOREIGN KEY (session_id) REFERENCES activity_session(id) ON DELETE CASCADE,
    CONSTRAINT fk_like_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT uq_session_like UNIQUE (session_id, user_id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- User indexes
CREATE INDEX idx_user_email ON app_user(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_username ON app_user(username) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_active ON app_user(is_active) WHERE is_active = TRUE;

-- Unit indexes
CREATE INDEX idx_unit_type ON unit(type);

-- Activity hierarchy indexes
CREATE INDEX idx_activity_type_category ON activity_type(category_id);
CREATE INDEX idx_subtype_type ON activity_subtype(activity_type_id, name);
CREATE INDEX idx_subtype_search ON activity_subtype USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- Session indexes
CREATE INDEX idx_session_user_date ON activity_session(user_id, started_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_session_type_date ON activity_session(activity_type_id, started_at DESC);
CREATE INDEX idx_session_subtype ON activity_session(user_id, activity_subtype_id, started_at DESC) WHERE activity_subtype_id IS NOT NULL;
CREATE INDEX idx_session_templates ON activity_session(user_id, is_template) WHERE is_template = TRUE;
CREATE INDEX idx_session_search ON activity_session USING gin(search_vector);
CREATE INDEX idx_session_date_trunc ON activity_session(user_id, DATE_TRUNC('day', started_at));

-- Exercise and set indexes
CREATE INDEX idx_exercise_session ON activity_exercise(session_id, exercise_order);
CREATE INDEX idx_exercise_subtype ON activity_exercise(activity_subtype_id);
CREATE INDEX idx_set_exercise ON exercise_set(exercise_id, set_number);
CREATE INDEX idx_set_weight ON exercise_set(weight DESC) WHERE weight IS NOT NULL;
CREATE INDEX idx_set_reps ON exercise_set(reps DESC) WHERE reps IS NOT NULL;

-- Metric indexes
CREATE INDEX idx_metric_session ON activity_metric(session_id, metric_name);
CREATE INDEX idx_metric_name_value ON activity_metric(metric_name, metric_value_numeric DESC NULLS LAST);
CREATE INDEX idx_template_activity ON activity_type_metric_template(activity_type_id, display_order);

-- Media indexes
CREATE INDEX idx_media_session ON session_media(session_id, created_at DESC);
CREATE INDEX idx_media_exercise ON session_media(exercise_id);
CREATE INDEX idx_progress_photos ON session_media(session_id, created_at DESC) WHERE is_progress_photo = TRUE;
CREATE INDEX idx_media_tags ON session_media USING gin(tags);

-- Goal indexes
CREATE INDEX idx_user_goals ON user_goal(user_id, is_active, target_date);
CREATE INDEX idx_goal_type ON user_goal(goal_type_id, is_active);
CREATE INDEX idx_milestone_goal ON goal_milestone(goal_id, is_achieved);

-- Personal record indexes
CREATE INDEX idx_user_prs ON personal_record(user_id, activity_subtype_id, record_type);
CREATE INDEX idx_pr_achieved ON personal_record(user_id, achieved_at DESC);
CREATE INDEX idx_pr_subtype ON personal_record(activity_subtype_id, record_value DESC);

-- Body metric indexes
CREATE INDEX idx_body_metrics ON user_body_metric(user_id, metric_type_id, measured_at DESC);

-- Program indexes
CREATE INDEX idx_programs_public ON workout_program(is_public, is_official) WHERE deleted_at IS NULL;
CREATE INDEX idx_program_creator ON workout_program(creator_id);
CREATE INDEX idx_program_search ON workout_program USING gin(search_vector);
CREATE INDEX idx_program_sessions ON program_session_template(program_id, week_number, day_number);
CREATE INDEX idx_template_exercises ON program_exercise_template(session_template_id, exercise_order);
CREATE INDEX idx_user_enrollments ON user_program_enrollment(user_id, is_active);
CREATE INDEX idx_program_enrollments ON user_program_enrollment(program_id, is_active);

-- Gamification indexes
CREATE INDEX idx_user_achievements ON user_achievement(user_id, earned_at DESC);
CREATE INDEX idx_user_streaks ON user_streak(user_id, current_streak_days DESC);
CREATE INDEX idx_streak_activity ON user_streak(activity_type_id);

-- Social indexes
CREATE INDEX idx_followers ON user_relationship(following_id);
CREATE INDEX idx_following ON user_relationship(follower_id);
CREATE INDEX idx_session_shares ON session_share(shared_by_user_id, visibility, created_at DESC);
CREATE INDEX idx_shared_session ON session_share(session_id);
CREATE INDEX idx_session_comments ON session_comment(session_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_comments ON session_comment(user_id, created_at DESC);
CREATE INDEX idx_session_likes ON session_like(session_id);
CREATE INDEX idx_user_likes ON session_like(user_id, created_at DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for app_user
CREATE TRIGGER trigger_user_updated_at
    BEFORE UPDATE ON app_user
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for activity_session
CREATE TRIGGER trigger_session_updated_at
    BEFORE UPDATE ON activity_session
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for user_goal
CREATE TRIGGER trigger_goal_updated_at
    BEFORE UPDATE ON user_goal
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for workout_program
CREATE TRIGGER trigger_program_updated_at
    BEFORE UPDATE ON workout_program
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for user_streak
CREATE TRIGGER trigger_streak_updated_at
    BEFORE UPDATE ON user_streak
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- MATERIALIZED VIEWS
-- ============================================================================

CREATE MATERIALIZED VIEW user_statistics AS
SELECT
    user_id,
    COUNT(*) as total_sessions,
    COUNT(DISTINCT DATE(started_at)) as total_days_active,
    MAX(started_at) as last_activity,
    SUM(duration_minutes) as total_minutes,
    AVG(rating) as avg_session_rating,
    SUM(estimated_calories) as total_calories,
    COUNT(*) FILTER (WHERE is_personal_record = TRUE) as total_prs
FROM activity_session
WHERE deleted_at IS NULL
GROUP BY user_id;

CREATE UNIQUE INDEX idx_user_stats_user ON user_statistics(user_id);

-- ============================================================================
-- ROW LEVEL SECURITY (Optional - commented out by default)
-- ============================================================================

-- Uncomment to enable RLS
/*
ALTER TABLE activity_session ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_goal ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_body_metric ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_data_isolation ON activity_session
    FOR ALL
    USING (user_id = current_setting('app.current_user_id')::INT);

CREATE POLICY user_goal_isolation ON user_goal
    FOR ALL
    USING (user_id = current_setting('app.current_user_id')::INT);

CREATE POLICY user_body_metric_isolation ON user_body_metric
    FOR ALL
    USING (user_id = current_setting('app.current_user_id')::INT);
*/

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE app_user IS 'User accounts and profile information';
COMMENT ON TABLE activity_session IS 'Individual activity session records';
COMMENT ON TABLE activity_exercise IS 'Exercises within a strength training session';
COMMENT ON TABLE exercise_set IS 'Individual sets within an exercise';
COMMENT ON TABLE activity_metric IS 'Flexible EAV metrics for various activity types';
COMMENT ON TABLE personal_record IS 'Personal records for exercises';
COMMENT ON TABLE user_goal IS 'User-defined fitness and activity goals';
COMMENT ON TABLE workout_program IS 'Pre-built and custom workout programs';
COMMENT ON MATERIALIZED VIEW user_statistics IS 'Pre-calculated user statistics for dashboard performance';

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
