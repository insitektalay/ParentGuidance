-- PGOS: add explanations_json to experiment_scores for "Why this won"

alter table if exists public.experiment_scores
    add column if not exists explanations_json jsonb default '{}'::jsonb;


