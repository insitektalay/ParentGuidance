-- PGOS: Experiment extensions
-- Adds ablation/planner/ensemble and regen_run_logs tables

create extension if not exists pgcrypto;

create table if not exists public.ablation_runs (
  id uuid primary key default gen_random_uuid(),
  experiment_run_id uuid not null references public.experiment_runs(id) on delete cascade,
  block_name text not null,
  param_key text not null,
  control_value text not null,
  test_value text not null,
  uplift_json jsonb not null default '{}'::jsonb,
  slice_def jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.block_plans (
  id uuid primary key default gen_random_uuid(),
  ablation_run_id uuid not null references public.ablation_runs(id) on delete cascade,
  plan_text text not null,
  params_json jsonb not null default '{}'::jsonb,
  judge_summary_json jsonb,
  picked boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.ensembles (
  id uuid primary key default gen_random_uuid(),
  experiment_run_id uuid not null references public.experiment_runs(id) on delete cascade,
  mode text not null,
  components_json jsonb not null,
  judge_summary_json jsonb,
  chosen boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.regen_run_logs (
  regen_run_id uuid not null references public.regen_runs(id) on delete cascade,
  ts timestamptz not null default now(),
  level text not null default 'info',
  message text not null
);

create index if not exists idx_regen_run_logs_run_ts on public.regen_run_logs(regen_run_id, ts desc);


