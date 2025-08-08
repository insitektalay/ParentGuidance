-- PGOS: Insight hygiene run tracking

create table if not exists public.insight_cleanup_runs (
  id uuid primary key default gen_random_uuid(),
  family_id uuid,
  mode text not null check (mode in ('dry_run','commit')),
  stats_json jsonb not null default '{}'::jsonb,
  errors jsonb not null default '[]'::jsonb,
  started_at timestamptz not null default now(),
  finished_at timestamptz
);

create index if not exists idx_insight_cleanup_runs_created on public.insight_cleanup_runs(started_at);
create index if not exists idx_insight_cleanup_runs_mode_start on public.insight_cleanup_runs(mode, started_at);
create index if not exists idx_insight_cleanup_runs_family_start on public.insight_cleanup_runs(family_id, started_at);


