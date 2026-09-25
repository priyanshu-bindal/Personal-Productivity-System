-- Migration: 007_account_deletion_scheduling.sql
-- Add server-side account deletion scheduling to profiles table
--
-- Design:
--   deletion_requested_at  — UTC timestamp when the user requested deletion
--   deletion_scheduled_for — UTC timestamp = deletion_requested_at + 15 days
--
-- The client stores the request here. Actual permanent deletion MUST be executed
-- by a trusted server-side job (e.g. Supabase pg_cron, Supabase Edge Function
-- triggered by a cron schedule, or an external scheduler).
--
-- IMPORTANT: The Flutter app NEVER deletes the account on its own.
-- It only writes deletion_requested_at and deletion_scheduled_for.
-- A background job must run daily (e.g. via pg_cron or a scheduled Edge Function):
--
--   DELETE FROM auth.users
--   WHERE id IN (
--     SELECT id FROM profiles
--     WHERE deletion_scheduled_for IS NOT NULL
--       AND deletion_scheduled_for <= NOW()
--   );
--
-- Because profiles has ON DELETE CASCADE from auth.users, this one DELETE
-- will cascade to all user data automatically.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS deletion_requested_at  TIMESTAMPTZ DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS deletion_scheduled_for TIMESTAMPTZ DEFAULT NULL;

-- Index for the scheduler query performance
CREATE INDEX IF NOT EXISTS idx_profiles_deletion_scheduled_for
  ON profiles(deletion_scheduled_for)
  WHERE deletion_scheduled_for IS NOT NULL;

-- ─── Server-Side Deletion Instruction ────────────────────────────────────────
--
-- Run this SQL via Supabase pg_cron (enable pg_cron extension in Dashboard):
--
--   SELECT cron.schedule(
--     'delete-scheduled-accounts',     -- job name
--     '0 3 * * *',                     -- daily at 03:00 UTC
--     $$
--       DELETE FROM auth.users
--       WHERE id IN (
--         SELECT id FROM profiles
--         WHERE deletion_scheduled_for IS NOT NULL
--           AND deletion_scheduled_for <= NOW()
--       );
--     $$
--   );
--
-- Alternatively, deploy a Supabase Edge Function with a cron trigger set to
-- run daily, using the Supabase service-role key (server-side only).
-- The service-role key must NEVER be bundled inside the Flutter app.
-- ─────────────────────────────────────────────────────────────────────────────
