-- Create experiment_runs table for tracking benchmark experiments
CREATE TABLE IF NOT EXISTS experiment_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES families(id) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    config JSONB NOT NULL, -- prompt templates, model, params, seed
    status TEXT CHECK (status IN ('queued', 'running', 'paused', 'completed', 'failed')) NOT NULL DEFAULT 'queued',
    run_type TEXT CHECK (run_type IN ('manual', 'dynamic_prompting')) NOT NULL DEFAULT 'manual',
    date_range JSONB DEFAULT '{}', -- {start, end} for situation filtering
    situation_filter JSONB DEFAULT '{}', -- additional filters
    progress JSONB DEFAULT '{}',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create experiment_scores table for tracking scoring metrics
CREATE TABLE IF NOT EXISTS experiment_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_run_id UUID REFERENCES experiment_runs(id) NOT NULL,
    situation_id UUID REFERENCES situations(id) NOT NULL,
    guidance_id UUID REFERENCES guidance(id) NOT NULL,
    gold_response_id UUID REFERENCES gold_responses(id),
    redline_response_id UUID REFERENCES redline_responses(id),
    
    -- Individual metric scores
    semantic_similarity FLOAT, -- embedding cosine similarity to gold
    string_overlap FLOAT, -- ROUGE-L score to gold
    style_tone_score FLOAT, -- LLM-graded 1-5
    
    -- Redline penalties
    redline_similarity FLOAT, -- semantic proximity to redline
    redline_keyword_hits INT, -- count of explicit phrase matches
    redline_penalty FLOAT, -- computed penalty score
    
    -- Composite score
    composite_score FLOAT NOT NULL, -- w_gold*GoldScore - w_redline*RedlinePenalty
    score_weights JSONB DEFAULT '{}', -- weights used for this calculation
    
    -- Detailed comparison data
    comparison_details JSONB DEFAULT '{}', -- per-section scores, diffs, etc
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add experiment_run_id to derived tables
ALTER TABLE guidance 
ADD COLUMN IF NOT EXISTS experiment_run_id UUID REFERENCES experiment_runs(id);

ALTER TABLE contextual_insights
ADD COLUMN IF NOT EXISTS experiment_run_id UUID REFERENCES experiment_runs(id);

ALTER TABLE insight_bullet_points
ADD COLUMN IF NOT EXISTS experiment_run_id UUID REFERENCES experiment_runs(id);

ALTER TABLE relevant_insights
ADD COLUMN IF NOT EXISTS experiment_run_id UUID REFERENCES experiment_runs(id);

-- Create indexes
CREATE INDEX idx_experiment_runs_family ON experiment_runs(family_id);
CREATE INDEX idx_experiment_runs_status ON experiment_runs(status);
CREATE INDEX idx_experiment_runs_created_by ON experiment_runs(created_by);

CREATE INDEX idx_exp_scores_run_situation ON experiment_scores(experiment_run_id, situation_id);
CREATE INDEX idx_exp_scores_composite ON experiment_scores(experiment_run_id, composite_score DESC);

CREATE INDEX IF NOT EXISTS idx_guidance_experiment_run ON guidance(experiment_run_id);
CREATE INDEX IF NOT EXISTS idx_contextual_insights_experiment_run ON contextual_insights(experiment_run_id);
CREATE INDEX IF NOT EXISTS idx_insight_bullet_points_experiment_run ON insight_bullet_points(experiment_run_id);
CREATE INDEX IF NOT EXISTS idx_relevant_insights_experiment_run ON relevant_insights(experiment_run_id);

-- Enable RLS
ALTER TABLE experiment_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE experiment_scores ENABLE ROW LEVEL SECURITY;

-- RLS policies for experiment_runs
CREATE POLICY "Users can view their family's experiment runs" ON experiment_runs
    FOR SELECT USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can create experiment runs for their family" ON experiment_runs
    FOR INSERT WITH CHECK (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can update their family's experiment runs" ON experiment_runs
    FOR UPDATE USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

-- RLS policies for experiment_scores
CREATE POLICY "Users can view their family's experiment scores" ON experiment_scores
    FOR SELECT USING (
        experiment_run_id IN (
            SELECT id FROM experiment_runs 
            WHERE family_id IN (
                SELECT family_id FROM profiles WHERE id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can create experiment scores" ON experiment_scores
    FOR INSERT WITH CHECK (
        experiment_run_id IN (
            SELECT id FROM experiment_runs 
            WHERE family_id IN (
                SELECT family_id FROM profiles WHERE id = auth.uid()
            )
        )
    );

-- Triggers for updated_at
CREATE TRIGGER update_experiment_runs_updated_at BEFORE UPDATE ON experiment_runs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();