-- Time Machine Schema Fix Script
-- This script attempts to fix common schema issues for Time Machine

\echo '=== FIXING TIME MACHINE SCHEMA ISSUES ==='

-- First, let's check what we're working with
DO $$
DECLARE
    has_situation_id_in_guidance BOOLEAN;
    guidance_id_column_type TEXT;
    situations_id_type TEXT;
BEGIN
    -- Check if guidance table has situation_id column
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'guidance' AND column_name = 'situation_id'
    ) INTO has_situation_id_in_guidance;
    
    IF has_situation_id_in_guidance THEN
        RAISE NOTICE '✓ guidance.situation_id column exists';
    ELSE
        RAISE NOTICE '❌ guidance.situation_id column MISSING';
        
        -- Check what ID columns guidance table actually has
        SELECT string_agg(column_name, ', ') INTO guidance_id_column_type
        FROM information_schema.columns 
        WHERE table_name = 'guidance' AND column_name LIKE '%id%';
        
        RAISE NOTICE 'guidance table has these ID columns: %', guidance_id_column_type;
    END IF;
    
    -- Check situations.id type
    SELECT data_type INTO situations_id_type
    FROM information_schema.columns 
    WHERE table_name = 'situations' AND column_name = 'id';
    
    RAISE NOTICE 'situations.id type: %', situations_id_type;
END $$;

-- Fix 1: If guidance table uses 'situation_id' but it's the wrong type
DO $$
DECLARE
    guidance_situation_id_type TEXT;
    situations_id_type TEXT;
BEGIN
    -- Get column types
    SELECT data_type INTO guidance_situation_id_type 
    FROM information_schema.columns 
    WHERE table_name = 'guidance' AND column_name = 'situation_id';
    
    SELECT data_type INTO situations_id_type 
    FROM information_schema.columns 
    WHERE table_name = 'situations' AND column_name = 'id';
    
    IF guidance_situation_id_type IS NOT NULL AND situations_id_type IS NOT NULL THEN
        IF guidance_situation_id_type != situations_id_type THEN
            RAISE NOTICE 'Type mismatch detected: guidance.situation_id is %, situations.id is %', 
                         guidance_situation_id_type, situations_id_type;
            
            -- Convert based on most common scenario
            IF situations_id_type = 'uuid' AND guidance_situation_id_type = 'text' THEN
                RAISE NOTICE 'Converting guidance.situation_id from TEXT to UUID...';
                ALTER TABLE guidance ALTER COLUMN situation_id TYPE UUID USING situation_id::UUID;
                RAISE NOTICE '✓ Converted guidance.situation_id to UUID';
            END IF;
        ELSE
            RAISE NOTICE '✓ Column types match: %', guidance_situation_id_type;
        END IF;
    END IF;
END $$;

-- Fix 2: If guidance table uses 'situationId' instead of 'situation_id'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'guidance' AND column_name = 'situationId'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'guidance' AND column_name = 'situation_id'
    ) THEN
        RAISE NOTICE 'Found camelCase situationId, renaming to situation_id...';
        ALTER TABLE guidance RENAME COLUMN "situationId" TO situation_id;
        RAISE NOTICE '✓ Renamed situationId to situation_id';
    END IF;
END $$;

-- Fix 3: Apply similar fixes to other tables that need situation_id
DO $$
DECLARE
    table_name TEXT;
    tables_to_fix TEXT[] := ARRAY['contextual_insights', 'relevant_insights', 'insight_bullet_points', 'deduplication_metrics'];
BEGIN
    FOREACH table_name IN ARRAY tables_to_fix
    LOOP
        -- Check if table exists
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = table_name) THEN
            -- Check for camelCase column and rename if needed
            IF EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = table_name AND column_name = 'situationId'
            ) AND NOT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = table_name AND column_name = 'situation_id'
            ) THEN
                EXECUTE format('ALTER TABLE %I RENAME COLUMN "situationId" TO situation_id', table_name);
                RAISE NOTICE '✓ Renamed situationId to situation_id in %', table_name;
            END IF;
        ELSE
            RAISE NOTICE '⚠ Table % does not exist', table_name;
        END IF;
    END LOOP;
END $$;

-- Fix 4: Ensure the reset function is created
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'reset_family_derived_data'
    ) THEN
        RAISE NOTICE '❌ reset_family_derived_data function missing';
        RAISE NOTICE 'Please run: migrations/time_machine/005_create_reset_archive_procedure.sql';
    ELSE
        RAISE NOTICE '✓ reset_family_derived_data function exists';
    END IF;
END $$;

-- Final verification
\echo 'Running final verification...'
DO $$
DECLARE
    verification_result TEXT := '';
    table_name TEXT;
    tables_to_check TEXT[] := ARRAY['guidance', 'contextual_insights', 'relevant_insights'];
BEGIN
    FOREACH table_name IN ARRAY tables_to_check
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = table_name) THEN
            IF EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = table_name AND column_name = 'situation_id'
            ) THEN
                verification_result := verification_result || '✓ ' || table_name || '.situation_id exists' || E'\n';
            ELSE
                verification_result := verification_result || '❌ ' || table_name || '.situation_id MISSING' || E'\n';
            END IF;
        ELSE
            verification_result := verification_result || '⚠ ' || table_name || ' table does not exist' || E'\n';
        END IF;
    END LOOP;
    
    RAISE NOTICE E'Final verification results:\n%', verification_result;
END $$;

\echo '=== SCHEMA FIX COMPLETE ==='
\echo 'If issues remain, you may need to run the full Time Machine migrations.'