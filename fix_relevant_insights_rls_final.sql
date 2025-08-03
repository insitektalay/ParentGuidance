-- Final RLS fix for relevant_insights table
-- Handle all existing policies properly

-- Drop ALL existing policies (using IF EXISTS to avoid errors)
DROP POLICY IF EXISTS "Users can read relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can insert relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can update relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can delete relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can read relevant insights for their guidance" ON relevant_insights;
DROP POLICY IF EXISTS "Users can insert relevant insights for their guidance" ON relevant_insights;
DROP POLICY IF EXISTS "Users can update relevant insights for their guidance" ON relevant_insights;
DROP POLICY IF EXISTS "Users can delete relevant insights for their guidance" ON relevant_insights;

-- Create new simplified policies based on guidance ownership
CREATE POLICY "guidance_read_policy" ON relevant_insights
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

CREATE POLICY "guidance_insert_policy" ON relevant_insights
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

CREATE POLICY "guidance_update_policy" ON relevant_insights
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

CREATE POLICY "guidance_delete_policy" ON relevant_insights
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

-- Verify the new policies
SELECT 
    tablename, 
    policyname, 
    cmd
FROM pg_policies 
WHERE tablename = 'relevant_insights'
ORDER BY policyname;