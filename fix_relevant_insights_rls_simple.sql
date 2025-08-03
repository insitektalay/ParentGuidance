-- Simple RLS fix for relevant_insights table
-- The current complex policy is failing, so let's try a simpler approach

-- First, drop all existing policies
DROP POLICY IF EXISTS "Users can read relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can insert relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can update relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can delete relevant insights for their family situations" ON relevant_insights;

-- Create simpler policies based on guidance ownership
-- This approach directly links to guidance table which we know works

-- READ policy
CREATE POLICY "Users can read relevant insights for their guidance" ON relevant_insights
    FOR SELECT USING (
        EXISTS (
            SELECT 1 
            FROM guidance g
            JOIN situations s ON s.id = g.situation_id
            JOIN profiles p ON p.family_id = s.family_id
            WHERE g.id = relevant_insights.guidance_id
            AND p.id = auth.uid()
        )
    );

-- INSERT policy  
CREATE POLICY "Users can insert relevant insights for their guidance" ON relevant_insights
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM guidance g
            JOIN situations s ON s.id = g.situation_id
            JOIN profiles p ON p.family_id = s.family_id
            WHERE g.id = relevant_insights.guidance_id
            AND p.id = auth.uid()
        )
    );

-- UPDATE policy
CREATE POLICY "Users can update relevant insights for their guidance" ON relevant_insights
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 
            FROM guidance g
            JOIN situations s ON s.id = g.situation_id
            JOIN profiles p ON p.family_id = s.family_id
            WHERE g.id = relevant_insights.guidance_id
            AND p.id = auth.uid()
        )
    );

-- DELETE policy
CREATE POLICY "Users can delete relevant insights for their guidance" ON relevant_insights
    FOR DELETE USING (
        EXISTS (
            SELECT 1 
            FROM guidance g
            JOIN situations s ON s.id = g.situation_id
            JOIN profiles p ON p.family_id = s.family_id
            WHERE g.id = relevant_insights.guidance_id
            AND p.id = auth.uid()
        )
    );

-- Verify the policies were created
SELECT 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd,
    LEFT(qual, 100) as qual_preview
FROM pg_policies 
WHERE tablename = 'relevant_insights'
ORDER BY policyname;