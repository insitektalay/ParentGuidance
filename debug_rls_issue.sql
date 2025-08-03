-- Debug script to understand why relevant_insights cannot be read despite being in the database

-- 1. Check current auth context
SELECT 
    auth.uid() as current_user_id,
    current_user as postgres_user;

-- 2. Check the insights that exist
SELECT 
    COUNT(*) as total_insights,
    guidance_id
FROM relevant_insights 
WHERE guidance_id = '110AC2FB-BA84-4987-8CDF-FB3B0634B7E6'
GROUP BY guidance_id;

-- 3. Check if user owns the situations for the insights
SELECT 
    ri.id as insight_id,
    ri.guidance_id,
    ri.situation_id,
    s.id as situation_id_check,
    s.family_id as situation_family_id,
    p.id as profile_id,
    p.email as profile_email,
    p.family_id as profile_family_id,
    auth.uid() as current_auth_uid,
    auth.uid()::text as current_auth_uid_text,
    CASE 
        WHEN p.id = auth.uid() THEN 'MATCH - User owns this'
        WHEN p.id IS NULL THEN 'NO PROFILE FOUND'
        ELSE 'NO MATCH - Different user'
    END as auth_check,
    CASE
        WHEN s.family_id = p.family_id THEN 'FAMILY MATCH'
        WHEN s.family_id IS NULL THEN 'NULL FAMILY'
        ELSE 'FAMILY MISMATCH'
    END as family_check
FROM relevant_insights ri
JOIN situations s ON s.id = ri.situation_id
LEFT JOIN profiles p ON (s.family_id = p.family_id OR s.family_id IS NULL)
WHERE ri.guidance_id = '110AC2FB-BA84-4987-8CDF-FB3B0634B7E6'
ORDER BY auth_check DESC
LIMIT 10;

-- 4. Check RLS policy existence
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'relevant_insights';

-- 5. Test a direct query mimicking what the app does
-- This is what RelevantInsightsService.getRelevantInsights() runs
SELECT * 
FROM relevant_insights 
WHERE guidance_id = '110AC2FB-BA84-4987-8CDF-FB3B0634B7E6'
ORDER BY created_at ASC;

-- 6. Check if there are multiple users with the same family_id
SELECT 
    p.id,
    p.email,
    p.family_id,
    COUNT(*) OVER (PARTITION BY p.family_id) as users_in_family
FROM profiles p
WHERE p.family_id IN (
    SELECT DISTINCT s.family_id 
    FROM situations s
    JOIN relevant_insights ri ON ri.situation_id = s.id
    WHERE ri.guidance_id = '110AC2FB-BA84-4987-8CDF-FB3B0634B7E6'
);

-- 7. Alternative simpler RLS policy that might work better
-- This checks guidance ownership instead of situation ownership
/*
-- First, drop existing policies
DROP POLICY IF EXISTS "Users can read relevant insights for their family situations" ON relevant_insights;

-- Create a simpler policy based on guidance table
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
*/