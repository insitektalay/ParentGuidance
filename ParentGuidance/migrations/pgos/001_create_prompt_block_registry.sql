-- PGOS: Prompt Block Registry
-- Creates registry tables for prompt blocks and cohort pinning

create extension if not exists pgcrypto;

create table if not exists public.prompt_blocks (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  version text not null,
  params_json jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  change_log text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.block_cohort_pins (
  id uuid primary key default gen_random_uuid(),
  block_id uuid not null references public.prompt_blocks(id) on delete cascade,
  issue_type text not null,
  age_band text not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_prompt_blocks_enabled_updated on public.prompt_blocks(enabled, updated_at desc);
create index if not exists idx_block_cohort_pins_block on public.block_cohort_pins(block_id);
create unique index if not exists uq_block_cohort_pin on public.block_cohort_pins(block_id, issue_type, age_band);


