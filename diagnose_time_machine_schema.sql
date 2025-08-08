-- Time Machine Schema Diagnostic Script
-- Run this in your Supabase SQL Editor to check current database schema

\echo '=== TIME MACHINE SCHEMA DIAGNOSTIC ==='

-- Check if Time Machine tables exist
\echo 'Checking Time Machine table existence...'
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'regen_runs') 
        THEN '✓ regen_runs exists' 
        ELSE '❌ regen_runs MISSING' 
    END as regen_runs_status,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'experiment_runs') 
        THEN '✓ experiment_runs exists' 
        ELSE '❌ experiment_runs MISSING' 
    END as experiment_runs_status,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'gold_responses') 
        THEN '✓ gold_responses exists' 
        ELSE '❌ gold_responses MISSING' 
    END as gold_responses_status,
    
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'redline_responses') 
        THEN '✓ redline_responses exists' 
        ELSE '❌ redline_responses MISSING' 
    END as redline_responses_status;

-- Check if core tables have the expected situation_id columns
\echo 'Checking situation_id column existence...'
SELECT 
    table_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = t.table_name AND column_name = 'situation_id'
        ) 
        THEN '✓ has situation_id' 
        ELSE '❌ NO situation_id' 
    END as situation_id_status,
    
    -- Show what ID columns actually exist
    STRING_AGG(column_name, ', ') as actual_id_columns
FROM (
    VALUES 
        ('guidance'),
        ('contextual_insights'), 
        ('relevant_insights'),
        ('insight_bullet_points'),
        ('deduplication_metrics')
) AS t(table_name)
LEFT JOIN information_schema.columns c ON c.table_name = t.table_name 
    AND (c.column_name LIKE '%_id' OR c.column_name = 'id')
WHERE c.table_name IS NOT NULL
GROUP BY t.table_name
ORDER BY t.table_name;

-- Check column types for situations.id vs guidance.situation_id
\echo 'Checking column type compatibility...'
SELECT 
    'situations.id' as column_ref,
    COALESCE(
        (SELECT data_type FROM information_schema.columns 
         WHERE table_name = 'situations' AND column_name = 'id'), 
        'TABLE NOT FOUND'
    ) as data_type
UNION ALL
SELECT 
    'guidance.situation_id' as column_ref,
    COALESCE(
        (SELECT data_type FROM information_schema.columns 
         WHERE table_name = 'guidance' AND column_name = 'situation_id'), 
        'COLUMN NOT FOUND'
    ) as data_type;

-- Check if reset function exists
\echo 'Checking reset function existence...'
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'reset_family_derived_data'
        ) 
        THEN '✓ reset_family_derived_data function exists' 
        ELSE '❌ reset_family_derived_data function MISSING' 
    END as function_status;

-- Show actual guidance table structure
\echo 'Guidance table structure:'
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'guidance'
ORDER BY ordinal_position;

\echo '=== DIAGNOSTIC COMPLETE ==='
\echo 'Next steps:'
\echo '1. If Time Machine tables are missing: Run run_time_machine_migrations.sql'
\echo '2. If situation_id columns are missing: Check column names and run fixes'
\echo '3. If types mismatch: Run fix_column_types.sql'