-- Performance Indexes for Supabase Optimization

-- 1. Accelerate /calendar ranged date queries which filter by user_id and scheduled_date
CREATE INDEX IF NOT EXISTS idx_learning_sessions_dates ON learning_sessions(user_id, scheduled_date);

-- 2. Accelerate getSkills() joins which fetch learning_sessions by skill_id
CREATE INDEX IF NOT EXISTS idx_learning_sessions_skill_id ON learning_sessions(skill_id);

-- 3. Accelerate getNotes() queries filtering by user_id and ordering by created_at
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(user_id, created_at DESC);

-- 4. Accelerate /money expenses queries which do ranged date scans by user
CREATE INDEX IF NOT EXISTS idx_expenses_dates ON expenses(user_id, expense_date DESC);
