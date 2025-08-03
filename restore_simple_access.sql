-- Restore Original Simple Table Access (No RLS)
-- This removes the RLS policies that broke the working implementation

-- Step 1: Remove ALL RLS policies from relevant_insights table
DROP POLICY IF EXISTS "read_family_insights" ON relevant_insights;
DROP POLICY IF EXISTS "insert_family_insights" ON relevant_insights;
DROP POLICY IF EXISTS "read_family_insights_simple" ON relevant_insights;
DROP POLICY IF EXISTS "insert_family_insights_simple" ON relevant_insights;
DROP POLICY IF EXISTS "Users can create relevant insights for their situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can delete relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can insert relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can read relevant insights for their family situations" ON relevant_insights;
DROP POLICY IF EXISTS "Users can read their own family's relevant insights" ON relevant_insights;
DROP POLICY IF EXISTS "Users can update relevant insights for their family situations" ON relevant_insights;

-- Step 2: Disable RLS entirely (restore original simple access)
ALTER TABLE relevant_insights DISABLE ROW LEVEL SECURITY;

-- Step 3: Verify no policies remain
SELECT 
    'RLS Policies Remaining' as status,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'relevant_insights';

-- Step 4: Test direct table access (should work now)
SELECT 
    'Direct Access Test' as test_type,
    COUNT(*) as total_insights,
    COUNT(DISTINCT guidance_id) as unique_guidance_ids
FROM relevant_insights;

-- Step 5: Show sample data to confirm table is accessible
SELECT 
    'Sample Data' as test_type,
    guidance_id,
    insight_type,
    LEFT(insight_content, 50) || '...' as content_preview
FROM relevant_insights 
ORDER BY created_at DESC 
LIMIT 5;