-- Add regen_run_id to all derived tables to track which regeneration run created them

-- Add to guidance table
ALTER TABLE guidance 
ADD COLUMN IF NOT EXISTS regen_run_id UUID REFERENCES regen_runs(id);

CREATE INDEX IF NOT EXISTS idx_guidance_regen_run ON guidance(regen_run_id);

-- Add to contextual_insights table  
ALTER TABLE contextual_insights
ADD COLUMN IF NOT EXISTS regen_run_id UUID REFERENCES regen_runs(id);

CREATE INDEX IF NOT EXISTS idx_contextual_insights_regen_run ON contextual_insights(regen_run_id);

-- Add to insight_bullet_points table (regulation insights)
ALTER TABLE insight_bullet_points
ADD COLUMN IF NOT EXISTS regen_run_id UUID REFERENCES regen_runs(id);

CREATE INDEX IF NOT EXISTS idx_insight_bullet_points_regen_run ON insight_bullet_points(regen_run_id);

-- Add to relevant_insights table
ALTER TABLE relevant_insights
ADD COLUMN IF NOT EXISTS regen_run_id UUID REFERENCES regen_runs(id);

CREATE INDEX IF NOT EXISTS idx_relevant_insights_regen_run ON relevant_insights(regen_run_id);

-- Add to framework_recommendations table
ALTER TABLE framework_recommendations
ADD COLUMN IF NOT EXISTS regen_run_id UUID REFERENCES regen_runs(id);

CREATE INDEX IF NOT EXISTS idx_framework_recommendations_regen_run ON framework_recommendations(regen_run_id);

-- Add to psychologist_notes table
ALTER TABLE psychologist_notes
ADD COLUMN IF NOT EXISTS regen_run_id UUID REFERENCES regen_runs(id);

CREATE INDEX IF NOT EXISTS idx_psychologist_notes_regen_run ON psychologist_notes(regen_run_id);