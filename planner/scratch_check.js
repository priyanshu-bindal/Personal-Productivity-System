const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres.ikooebbiodhqfjfqwjsa:iamarobot1621%40X@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function run() {
  await client.connect();

  const sessionsRes = await client.query(`
    SELECT s.name, ls.scheduled_date, ls.status, ls.planned_duration, ls.created_at
    FROM public.learning_sessions ls
    JOIN public.skills s ON s.id = ls.skill_id
    WHERE ls.user_id = '3b60a165-3cc7-4ef2-b6b5-5ecc6716fb22'
      AND ls.scheduled_date BETWEEN '2026-10-10' AND '2026-10-16'
    ORDER BY ls.scheduled_date ASC, s.name ASC;
  `);
  console.log('=== SESSIONS BETWEEN OCT 10 AND OCT 16 ===');
  console.table(sessionsRes.rows.map(r => ({
    name: r.name,
    date: r.scheduled_date ? r.scheduled_date.toISOString().split('T')[0] : null,
    status: r.status,
    duration: r.planned_duration,
    created_at: r.created_at
  })));

  await client.end();
}

run().catch(console.error);
