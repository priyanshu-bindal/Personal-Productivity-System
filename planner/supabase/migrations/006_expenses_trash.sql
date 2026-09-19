-- Migration: 006_expenses_trash.sql
-- Add deleted_at to expenses table for 30-Day Trash lifecycle.

ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL;

-- Composite index to accelerate querying active expenses (deleted_at IS NULL)
-- as well as trashed expenses (deleted_at IS NOT NULL) per user.
CREATE INDEX IF NOT EXISTS idx_expenses_user_deleted_at 
ON expenses(user_id, deleted_at);
