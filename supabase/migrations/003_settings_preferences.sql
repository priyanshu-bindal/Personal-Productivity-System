-- Migration: 003_settings_preferences.sql
-- Add user preference columns to profiles table

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS default_session_duration INTEGER DEFAULT 60,
ADD COLUMN IF NOT EXISTS practice_reminders BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS daily_reminder_time TEXT DEFAULT '09:00',
ADD COLUMN IF NOT EXISTS theme TEXT DEFAULT 'dark';
