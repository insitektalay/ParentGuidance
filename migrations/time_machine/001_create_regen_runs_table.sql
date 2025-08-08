-- Create regen_runs table for tracking time machine regeneration runs
CREATE TABLE IF NOT EXISTS regen_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    status TEXT CHECK (status IN ('running', 'paused', 'completed', 'failed')) NOT NULL DEFAULT 'running',
    config JSONB NOT NULL, -- stores all run parameters
    progress JSONB DEFAULT '{}', -- current situation index, counts, etc
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_regen_runs_family ON regen_runs(family_id);
CREATE INDEX idx_regen_runs_status ON regen_runs(status);
CREATE INDEX idx_regen_runs_created_by ON regen_runs(created_by);

-- Enable RLS
ALTER TABLE regen_runs ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can view their family's regen runs" ON regen_runs
    FOR SELECT USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can create regen runs for their family" ON regen_runs
    FOR INSERT WITH CHECK (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can update their family's regen runs" ON regen_runs
    FOR UPDATE USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_regen_runs_updated_at BEFORE UPDATE ON regen_runs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();