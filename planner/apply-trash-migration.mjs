// Run with: node apply-trash-migration.mjs
// Checks if deleted_at exists in Supabase expenses table.

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://ikooebbiodhqfjfqwjsa.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlrb29lYmJpb2RocWZqZnF3anNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwOTUyMTUsImV4cCI6MjEwMzY3MTIxNX0.jAbFJmpKxszbZougFUjYXKGGHj68Ys4tj7MWAj1c-2g'

const supabase = createClient(supabaseUrl, supabaseKey)

console.log('Testing if column `deleted_at` is accessible on table `expenses`...')

const { data, error } = await supabase
  .from('expenses')
  .select('id, deleted_at')
  .limit(1)

if (error) {
  console.log('Column not yet applied or error returned:')
  console.log(error)
  console.log('\n========================================')
  console.log('ACTION NEEDED IN SUPABASE SQL EDITOR')
  console.log('========================================')
  console.log('Open: https://supabase.com/dashboard/project/ikooebbiodhqfjfqwjsa/sql/new')
  console.log('Paste and execute:')
  console.log(`
ALTER TABLE expenses 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS idx_expenses_user_deleted_at 
ON expenses(user_id, deleted_at);
  `)
  console.log('========================================')
} else {
  console.log('SUCCESS: `deleted_at` column is present and accessible on table `expenses`!')
  console.log('Sample record query returned:', data)
}
