-- =====================================================
-- Fix insight_bullet_points table to allow NULL situation_id
-- =====================================================
-- This migration allows the situation_id column to be nullable
-- to support the regeneration feature where insights are extracted
-- from multiple situations and don't belong to any specific one.
--
-- Run this script in your Supabase SQL Editor
-- =====================================================

-- Step 1: Alter the column to allow NULL values
ALTER TABLE insight_bullet_points 
ALTER COLUMN situation_id DROP NOT NULL;

-- Step 2: Add a comment to document why this column is nullable
COMMENT ON COLUMN insight_bullet_points.situation_id IS 
'References the situation this insight was extracted from. Can be NULL for insights generated during bulk regeneration from multiple situations.';

-- Step 3: Verify the change
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM 
    information_schema.columns
WHERE 
    table_name = 'insight_bullet_points' 
    AND column_name = 'situation_id';

-- Expected result: is_nullable should be 'YES'

-- Step 4: Test that we can insert with NULL situation_id
-- (This is just a test - it will be rolled back)
DO $$
DECLARE
    test_family_id UUID;
BEGIN
    -- Get any existing family_id for testing
    SELECT id INTO test_family_id FROM families LIMIT 1;
    
    IF test_family_id IS NOT NULL THEN
        -- Try to insert a test record with NULL situation_id
        INSERT INTO insight_bullet_points (
            id,
            family_id,
            situation_id,
            category,
            content,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            test_family_id,
            NULL, -- This should now work
            'Core',
            'Test insight with null situation_id',
            NOW(),
            NOW()
        );
        
        -- Clean up the test record
        DELETE FROM insight_bullet_points 
        WHERE content = 'Test insight with null situation_id';
        
        RAISE NOTICE 'Success: Table now accepts NULL situation_id values';
    ELSE
        RAISE NOTICE 'No families found for testing, but schema change completed';
    END IF;
END $$;

-- =====================================================
-- ROLLBACK SCRIPT (if needed)
-- =====================================================
-- If you need to revert this change, run:
-- ALTER TABLE insight_bullet_points 
-- ALTER COLUMN situation_id SET NOT NULL;
--
-- Note: This will fail if there are any NULL values in the column