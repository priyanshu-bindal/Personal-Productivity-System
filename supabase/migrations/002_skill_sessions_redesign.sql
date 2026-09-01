-- Migration: 002_skill_sessions_redesign.sql
-- Add new columns for skill schedules and session tracking

ALTER TABLE skills 
ADD COLUMN IF NOT EXISTS session_duration INTEGER DEFAULT 60,
ADD COLUMN IF NOT EXISTS preferred_days TEXT[] DEFAULT ARRAY['Monday', 'Wednesday', 'Friday']::TEXT[],
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

ALTER TABLE learning_sessions
ADD COLUMN IF NOT EXISTS scheduled_date DATE DEFAULT CURRENT_DATE,
ADD COLUMN IF NOT EXISTS planned_duration INTEGER DEFAULT 60,
ADD COLUMN IF NOT EXISTS actual_duration INTEGER,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'planned',
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- Unique constraint so a skill doesn't have duplicate planned sessions on the same date for a user
ALTER TABLE learning_sessions
ADD CONSTRAINT unique_skill_scheduled_date UNIQUE (user_id, skill_id, scheduled_date);
