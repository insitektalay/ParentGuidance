-- Fix Column Type Mismatches
-- Run this after diagnose_column_types.sql to align types

-- Step 1: Align relevant_insights.guidance_id with guidance.id type
-- (Most likely scenario: guidance.id is UUID, relevant_insights.guidance_id is TEXT)

DO $$
DECLARE
    guidance_id_type text;
    ri_guidance_id_type text;
BEGIN
    -- Get actual column types
    SELECT data_type INTO guidance_id_type 
    FROM information_schema.columns 
    WHERE table_name = 'guidance' AND column_name = 'id' AND table_schema = 'public';
    
    SELECT data_type INTO ri_guidance_id_type 
    FROM information_schema.columns 
    WHERE table_name = 'relevant_insights' AND column_name = 'guidance_id' AND table_schema = 'public';
    
    RAISE NOTICE 'guidance.id type: %', guidance_id_type;
    RAISE NOTICE 'relevant_insights.guidance_id type: %', ri_guidance_id_type;
    
    -- Align types if they're different
    IF guidance_id_type != ri_guidance_id_type THEN
        RAISE NOTICE 'Type mismatch detected, fixing...';
        
        IF guidance_id_type = 'uuid' AND ri_guidance_id_type = 'text' THEN
            -- Convert TEXT to UUID
            RAISE NOTICE 'Converting relevant_insights.guidance_id from TEXT to UUID';
            ALTER TABLE relevant_insights 
            ALTER COLUMN guidance_id TYPE uuid USING guidance_id::uuid;
            
        ELSIF guidance_id_type = 'text' AND ri_guidance_id_type = 'uuid' THEN
            -- Convert UUID to TEXT
            RAISE NOTICE 'Converting relevant_insights.guidance_id from UUID to TEXT';
            ALTER TABLE relevant_insights 
            ALTER COLUMN guidance_id TYPE text USING guidance_id::text;
            
        ELSE
            RAISE NOTICE 'Unsupported type conversion: % to %', ri_guidance_id_type, guidance_id_type;
        END IF;
    ELSE
        RAISE NOTICE 'Types already match, no conversion needed';
    END IF;
END $$;

-- Step 2: Check and align guidance.situation_id with situations.id type
DO $$
DECLARE
    situations_id_type text;
    guidance_situation_id_type text;
BEGIN
    -- Get actual column types
    SELECT data_type INTO situations_id_type 
    FROM information_schema.columns 
    WHERE table_name = 'situations' AND column_name = 'id' AND table_schema = 'public';
    
    SELECT data_type INTO guidance_situation_id_type 
    FROM information_schema.columns 
    WHERE table_name = 'guidance' AND column_name = 'situation_id' AND table_schema = 'public';
    
    RAISE NOTICE 'situations.id type: %', situations_id_type;
    RAISE NOTICE 'guidance.situation_id type: %', guidance_situation_id_type;
    
    -- Align types if they're different
    IF situations_id_type != guidance_situation_id_type THEN
        RAISE NOTICE 'Type mismatch detected, fixing...';
        
        IF situations_id_type = 'uuid' AND guidance_situation_id_type = 'text' THEN
            -- Convert TEXT to UUID
            RAISE NOTICE 'Converting guidance.situation_id from TEXT to UUID';
            ALTER TABLE guidance 
            ALTER COLUMN situation_id TYPE uuid USING situation_id::uuid;
            
        ELSIF situations_id_type = 'text' AND guidance_situation_id_type = 'uuid' THEN
            -- Convert UUID to TEXT  
            RAISE NOTICE 'Converting guidance.situation_id from UUID to TEXT';
            ALTER TABLE guidance 
            ALTER COLUMN situation_id TYPE text USING situation_id::text;
            
        ELSE
            RAISE NOTICE 'Unsupported type conversion: % to %', guidance_situation_id_type, situations_id_type;
        END IF;
    ELSE
        RAISE NOTICE 'Types already match, no conversion needed';
    END IF;
END $$;

-- Step 3: Verify all types are now aligned
SELECT 
    'Type Verification' as check_type,
    'guidance.id: ' || g_id.data_type as guidance_id_type,
    'relevant_insights.guidance_id: ' || ri_gid.data_type as ri_guidance_id_type,
    'situations.id: ' || s_id.data_type as situations_id_type,
    'guidance.situation_id: ' || g_sid.data_type as guidance_situation_id_type
FROM 
    (SELECT data_type FROM information_schema.columns WHERE table_name = 'guidance' AND column_name = 'id') g_id,
    (SELECT data_type FROM information_schema.columns WHERE table_name = 'relevant_insights' AND column_name = 'guidance_id') ri_gid,
    (SELECT data_type FROM information_schema.columns WHERE table_name = 'situations' AND column_name = 'id') s_id,
    (SELECT data_type FROM information_schema.columns WHERE table_name = 'guidance' AND column_name = 'situation_id') g_sid;

-- Step 4: Test the joins that were failing
SELECT 'Join Test' as test_type, COUNT(*) as join_count
FROM relevant_insights ri
JOIN guidance g ON g.id = ri.guidance_id
JOIN situations s ON s.id = g.situation_id
LIMIT 1;