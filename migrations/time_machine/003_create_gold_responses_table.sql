-- Create gold_responses table for benchmark desired responses
CREATE TABLE IF NOT EXISTS gold_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    situation_id UUID REFERENCES situations(id) NOT NULL,
    family_id UUID REFERENCES families(id) NOT NULL,
    version INT NOT NULL DEFAULT 1,
    full_response TEXT NOT NULL,
    response_sections JSONB DEFAULT '{}', -- {title, steps, tone, etc}
    author_id UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(situation_id, version)
);

-- Create redline_responses table for undesired content benchmarks
CREATE TABLE IF NOT EXISTS redline_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    situation_id UUID REFERENCES situations(id) NOT NULL,
    family_id UUID REFERENCES families(id) NOT NULL,
    version INT NOT NULL DEFAULT 1,
    full_response TEXT NOT NULL,
    response_sections JSONB DEFAULT '{}', -- {title, steps, tone, etc}
    author_id UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(situation_id, version)
);

-- Create indexes
CREATE INDEX idx_gold_responses_situation ON gold_responses(situation_id);
CREATE INDEX idx_gold_responses_family ON gold_responses(family_id);
CREATE INDEX idx_redline_responses_situation ON redline_responses(situation_id);
CREATE INDEX idx_redline_responses_family ON redline_responses(family_id);

-- Enable RLS
ALTER TABLE gold_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE redline_responses ENABLE ROW LEVEL SECURITY;

-- RLS policies for gold_responses
CREATE POLICY "Users can view their family's gold responses" ON gold_responses
    FOR SELECT USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can create gold responses for their family" ON gold_responses
    FOR INSERT WITH CHECK (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can update their family's gold responses" ON gold_responses
    FOR UPDATE USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

-- RLS policies for redline_responses
CREATE POLICY "Users can view their family's redline responses" ON redline_responses
    FOR SELECT USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can create redline responses for their family" ON redline_responses
    FOR INSERT WITH CHECK (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

CREATE POLICY "Users can update their family's redline responses" ON redline_responses
    FOR UPDATE USING (
        family_id IN (
            SELECT family_id FROM profiles WHERE id = auth.uid()
        )
    );

-- Triggers for updated_at
CREATE TRIGGER update_gold_responses_updated_at BEFORE UPDATE ON gold_responses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_redline_responses_updated_at BEFORE UPDATE ON redline_responses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();