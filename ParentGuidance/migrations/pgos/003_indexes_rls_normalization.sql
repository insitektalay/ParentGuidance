-- PGOS: indexes and normalization helpers

-- Suggested indexes to support query patterns
create index if not exists idx_contextual_insights_family_created on public.contextual_insights(family_id, created_at desc);
create index if not exists idx_contextual_insights_family_category on public.contextual_insights(family_id, category);
create index if not exists idx_insight_bullets_family_category on public.insight_bullet_points(family_id, category);
create index if not exists idx_guidance_situation_created on public.guidance(situation_id, created_at desc);
create index if not exists idx_guidance_family_created on public.guidance(regen_run_id, created_at desc);
create index if not exists idx_experiment_scores_experiment on public.experiment_scores(experiment_run_id);

-- Optional: RLS-safe views for lowercased family_id (if needed)
-- This is a placeholder; implement according to your RLS policies
-- Enable RLS
alter table if exists public.prompt_blocks enable row level security;
alter table if exists public.experiment_scores enable row level security;
alter table if exists public.ablation_runs enable row level security;

-- Roles assumed: service_role, operator_role, user_role
-- Prompt blocks: operator/service only
drop policy if exists prompt_blocks_operator_access on public.prompt_blocks;
create policy prompt_blocks_operator_access on public.prompt_blocks
    for all
    using (current_setting('request.jwt.claims', true)::jsonb ? 'role' and
           ( (current_setting('request.jwt.claims', true)::jsonb ->> 'role') in ('operator','service_role') ));

-- Experiment scores: family-scoped read, operator/service write
drop policy if exists experiment_scores_read_family on public.experiment_scores;
create policy experiment_scores_read_family on public.experiment_scores
    for select
    using (exists (
        select 1 from public.experiment_runs r
        where r.id = experiment_scores.experiment_run_id
    ));

drop policy if exists experiment_scores_write_operator on public.experiment_scores;
create policy experiment_scores_write_operator on public.experiment_scores
    for all
    using ((current_setting('request.jwt.claims', true)::jsonb ->> 'role') in ('operator','service_role'));

-- Ablation runs: operator only
drop policy if exists ablation_runs_operator on public.ablation_runs;
create policy ablation_runs_operator on public.ablation_runs
    for all
    using ((current_setting('request.jwt.claims', true)::jsonb ->> 'role') in ('operator','service_role'));

