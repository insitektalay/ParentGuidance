-- Clean slate approach - remove ALL policies and create new ones
-- This addresses the multiple conflicting policies shown in the Supabase dashboard

-- Step 1: Drop ALL existing policies (including the ones visible in your screenshot)
DROP POLICY IF EXISTS "Users can create relevant insights for their situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can delete relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can insert relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can read relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can read their own family's relevant insights" ON relevant_insights;
DROP POLICY IF EXISTS "Users can update relevant insights for their family situations" ON relevant_insights;

-- Also drop any policies from previous attempts
DROP POLICY IF EXISTS "guidance_read_policy" ON relevant_insights;
DROP POLICY IF EXISTS "guidance_insert_policy" ON relevant_insights;
DROP POLICY IF EXISTS "guidance_update_policy" ON relevant_insights;
DROP POLICY IF EXISTS "guidance_delete_policy" ON relevant_insights;

-- Step 2: Verify all policies are removed
SELECT 
    'Before creating new policies' as status,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'relevant_insights';

-- Step 3: Create ONE simple read policy that should work
-- This is the most critical one for fixing the Library view issue
CREATE POLICY "read_family_insights" ON relevant_insights
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

-- Step 4: Create simple insert policy for saving insights
CREATE POLICY "insert_family_insights" ON relevant_insights
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

-- Step 5: Verify only our new policies exist
SELECT 
    'After creating new policies' as status,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'relevant_insights'
ORDER BY policyname;