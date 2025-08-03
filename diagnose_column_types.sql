-- Precise Column Type Diagnosis
-- Run this first to identify exact type mismatches

-- Check all relevant ID column types
SELECT 
    table_name,
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public'
  AND (
    (table_name = 'guidance' AND column_name = 'id') OR
    (table_name = 'guidance' AND column_name = 'situation_id') OR
    (table_name = 'situations' AND column_name = 'id') OR
    (table_name = 'relevant_insights' AND column_name = 'guidance_id') OR
    (table_name = 'relevant_insights' AND column_name = 'situation_id') OR
    (table_name = 'relevant_insights' AND column_name = 'family_id') OR
    (table_name = 'profiles' AND column_name = 'id') OR
    (table_name = 'profiles' AND column_name = 'family_id')
  )
ORDER BY table_name, column_name;

-- Check for any existing foreign key constraints
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('relevant_insights', 'guidance', 'situations')
ORDER BY tc.table_name;

-- Sample actual data types from tables (if they have data)
SELECT 'guidance.id type check' as test, pg_typeof(id) as actual_type 
FROM guidance LIMIT 1;

SELECT 'relevant_insights.guidance_id type check' as test, pg_typeof(guidance_id) as actual_type 
FROM relevant_insights LIMIT 1;

SELECT 'situations.id type check' as test, pg_typeof(id) as actual_type 
FROM situations LIMIT 1;

-- Check if family_id column exists in relevant_insights
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'relevant_insights' 
              AND column_name = 'family_id' 
              AND table_schema = 'public'
        ) THEN 'family_id column EXISTS'
        ELSE 'family_id column MISSING'
    END as family_id_status;