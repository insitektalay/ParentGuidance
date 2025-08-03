-- Fix Row Level Security policies for relevant_insights table
-- This table was missing RLS policies, causing insights to be saved but not readable

-- Enable RLS on relevant_insights table
ALTER TABLE relevant_insights ENABLE ROW LEVEL SECURITY;

-- Allow users to insert relevant insights for their family's situations
CREATE POLICY "Users can insert relevant insights for their family situations" ON relevant_insights
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM situations s
            JOIN profiles p ON (s.family_id = p.family_id OR s.family_id IS NULL)
            WHERE s.id = relevant_insights.situation_id 
            AND p.id = auth.uid()
        )
    );

-- Allow users to read relevant insights for their family's situations
CREATE POLICY "Users can read relevant insights for their family situations" ON relevant_insights
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM situations s
            JOIN profiles p ON (s.family_id = p.family_id OR s.family_id IS NULL)
            WHERE s.id = relevant_insights.situation_id 
            AND p.id = auth.uid()
        )
    );

-- Allow users to update relevant insights for their family's situations
CREATE POLICY "Users can update relevant insights for their family situations" ON relevant_insights
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM situations s
            JOIN profiles p ON (s.family_id = p.family_id OR s.family_id IS NULL)
            WHERE s.id = relevant_insights.situation_id 
            AND p.id = auth.uid()
        )
    );

-- Allow users to delete relevant insights for their family's situations
CREATE POLICY "Users can delete relevant insights for their family situations" ON relevant_insights
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM situations s
            JOIN profiles p ON (s.family_id = p.family_id OR s.family_id IS NULL)
            WHERE s.id = relevant_insights.situation_id 
            AND p.id = auth.uid()
        )
    );

-- Grant necessary permissions to authenticated users
GRANT ALL ON TABLE relevant_insights TO authenticated;

-- Verify the policies were created
SELECT tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'relevant_insights';