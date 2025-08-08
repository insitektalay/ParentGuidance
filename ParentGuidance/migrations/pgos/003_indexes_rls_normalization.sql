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


