-- PGOS: add plan_id and ensemble_id to experiment_scores

alter table if exists public.experiment_scores
    add column if not exists plan_id uuid;

alter table if exists public.experiment_scores
    add column if not exists ensemble_id uuid;


