-- Comprehensive debug script for relevant insights RLS issue
-- This will help us understand why insights are saved but not readable in the app

-- 1. First, let's see a recent guidance ID to work with
SELECT 
    g.id as guidance_id,
    g.situation_id,
    g.created_at,
    s.family_id
FROM guidance g
JOIN situations s ON g.situation_id = s.id
WHERE g.created_at > NOW() - INTERVAL '1 hour'
ORDER BY g.created_at DESC
LIMIT 1;

-- 2. Count insights for recent guidances (proves they exist)
SELECT 
    guidance_id,
    COUNT(*) as insight_count,
    MAX(created_at) as latest_created
FROM relevant_insights
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY guidance_id;

-- 3. Check the exact RLS policies on relevant_insights
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'relevant_insights'
ORDER BY policyname;

-- 4. Test if a specific user can see insights (replace with actual user ID)
-- This simulates what the app does
SET LOCAL role TO authenticated;
SET LOCAL request.jwt.claims.sub TO 'YOUR_USER_ID_HERE'; -- Replace with actual user ID

SELECT 
    ri.id,
    ri.guidance_id,
    ri.insight_id,
    ri.created_at
FROM relevant_insights ri
WHERE ri.guidance_id IN (
    SELECT id FROM guidance 
    WHERE created_at > NOW() - INTERVAL '1 hour'
    LIMIT 1
);

-- Reset role
RESET role;

-- 5. Check the join conditions in the RLS policy
-- Let's trace through the policy logic step by step
WITH recent_guidance AS (
    SELECT id, situation_id 
    FROM guidance 
    WHERE created_at > NOW() - INTERVAL '1 hour' 
    LIMIT 1
),
situation_info AS (
    SELECT 
        s.id as situation_id,
        s.family_id,
        rg.id as guidance_id
    FROM situations s
    JOIN recent_guidance rg ON s.id = rg.situation_id
),
profile_info AS (
    SELECT 
        p.id as profile_id,
        p.family_id,
        p.email
    FROM profiles p
    WHERE p.id = 'YOUR_USER_ID_HERE' -- Replace with actual user ID
)
SELECT 
    'Guidance' as step,
    rg.id as guidance_id,
    rg.situation_id
FROM recent_guidance rg
UNION ALL
SELECT 
    'Situation' as step,
    si.guidance_id,
    si.family_id::text
FROM situation_info si
UNION ALL
SELECT 
    'Profile' as step,
    pi.profile_id::text,
    pi.family_id::text
FROM profile_info pi;

-- 6. Direct test of the RLS policy condition
-- This is the exact condition from the policy
WITH test_data AS (
    SELECT 
        ri.id,
        ri.guidance_id,
        ri.situation_id,
        s.family_id as situation_family_id,
        p.id as profile_id,
        p.family_id as profile_family_id,
        CASE 
            WHEN s.family_id = p.family_id THEN 'FAMILY MATCH'
            WHEN s.family_id IS NULL THEN 'NULL FAMILY'
            ELSE 'NO MATCH'
        END as match_status
    FROM relevant_insights ri
    JOIN situations s ON s.id = ri.situation_id
    LEFT JOIN profiles p ON (s.family_id = p.family_id OR s.family_id IS NULL)
    WHERE ri.created_at > NOW() - INTERVAL '1 hour'
        AND p.id = 'YOUR_USER_ID_HERE' -- Replace with actual user ID
)
SELECT * FROM test_data;

-- 7. Check if insights have proper situation_id references
SELECT 
    ri.id,
    ri.guidance_id,
    ri.situation_id,
    CASE 
        WHEN s.id IS NULL THEN 'MISSING SITUATION'
        ELSE 'SITUATION EXISTS'
    END as situation_status
FROM relevant_insights ri
LEFT JOIN situations s ON s.id = ri.situation_id
WHERE ri.created_at > NOW() - INTERVAL '1 hour';

-- 8. Alternative RLS policy that might work better
-- This uses the guidance table for authorization instead of situations
/*
BEGIN;

-- Drop existing policy
DROP POLICY IF EXISTS "Users can read relevant insights for their family situations" ON relevant_insights;

-- Create new policy based on guidance ownership
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

-- Test the new policy would work
SELECT COUNT(*) as would_be_readable
FROM relevant_insights ri
WHERE EXISTS (
    SELECT 1 
    FROM guidance g
    JOIN situations s ON s.id = g.situation_id
    JOIN profiles p ON p.family_id = s.family_id
    WHERE g.id = ri.guidance_id
    AND p.id = 'YOUR_USER_ID_HERE' -- Replace with actual user ID
);

ROLLBACK; -- Remove this line to commit the change
*/