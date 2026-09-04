// Run with: node apply-migration.mjs
// This applies the 002_skill_sessions_redesign migration to your Supabase database.

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://ikooebbiodhqfjfqwjsa.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlrb29lYmJpb2RocWZqZnF3anNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwOTUyMTUsImV4cCI6MjEwMzY3MTIxNX0.jAbFJmpKxszbZougFUjYXKGGHj68Ys4tj7MWAj1c-2g'

const supabase = createClient(supabaseUrl, supabaseKey)

// We can't run raw DDL via anon key. Instead, use the Supabase REST SQL endpoint.
// The user must run this SQL in the Supabase Dashboard SQL Editor.

const migrationSQL = `
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
`

console.log('========================================')
console.log('MANUAL STEP REQUIRED')
console.log('========================================')
console.log('')
console.log('Please go to your Supabase Dashboard SQL Editor:')
console.log(`  https://supabase.com/dashboard/project/ikooebbiodhqfjfqwjsa/sql/new`)
console.log('')
console.log('Paste and run the following SQL:')
console.log('')
console.log(migrationSQL)
console.log('')
console.log('Then also run:')
console.log('')
console.log(`ALTER TABLE learning_sessions`)
console.log(`ADD CONSTRAINT unique_skill_scheduled_date UNIQUE (user_id, skill_id, scheduled_date);`)
console.log('')
console.log('========================================')
