-- =====================================================
-- Cleanup Duplicates Before Adding Vector Schema
-- =====================================================
-- This script identifies and removes duplicate insights before
-- adding the unique indexes and vector embedding columns.
--
-- Run this script BEFORE add_vector_embeddings_schema.sql
-- =====================================================

-- Step 1: Identify duplicates in insight_bullet_points
SELECT 
    'insight_bullet_points' as table_name,
    family_id,
    category,
    md5(lower(trim(content))) as content_hash,
    content,
    COUNT(*) as duplicate_count,
    array_agg(id ORDER BY created_at DESC) as all_ids,
    array_agg(created_at ORDER BY created_at DESC) as all_dates
FROM insight_bullet_points
WHERE content IS NOT NULL AND content != ''
GROUP BY family_id, category, md5(lower(trim(content))), content
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, family_id, category;

-- Step 2: Identify duplicates in contextual_insights
SELECT 
    'contextual_insights' as table_name,
    family_id,
    category,
    md5(lower(trim(content))) as content_hash,
    content,
    COUNT(*) as duplicate_count,
    array_agg(id ORDER BY created_at DESC) as all_ids,
    array_agg(created_at ORDER BY created_at DESC) as all_dates
FROM contextual_insights
WHERE content IS NOT NULL AND content != ''
GROUP BY family_id, category, md5(lower(trim(content))), content
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, family_id, category;

-- =====================================================
-- CLEANUP FUNCTIONS
-- =====================================================

-- Function to remove duplicates keeping the most recent one
CREATE OR REPLACE FUNCTION cleanup_insight_duplicates()
RETURNS TABLE (
    table_name text,
    duplicates_removed integer,
    families_affected integer
) AS $$
DECLARE
    removed_bullet_points integer := 0;
    removed_contextual integer := 0;
    families_bullet_points integer := 0;
    families_contextual integer := 0;
BEGIN
    -- Clean up insight_bullet_points duplicates
    -- Keep the most recent record (highest created_at) for each duplicate group
    WITH duplicates AS (
        SELECT 
            family_id,
            category,
            md5(lower(trim(content))) as content_hash,
            array_agg(id ORDER BY created_at DESC) as ids,
            COUNT(*) as dup_count
        FROM insight_bullet_points
        WHERE content IS NOT NULL AND content != ''
        GROUP BY family_id, category, md5(lower(trim(content)))
        HAVING COUNT(*) > 1
    ),
    ids_to_delete AS (
        SELECT 
            unnest(ids[2:]) as id_to_delete,
            family_id
        FROM duplicates
    )
    DELETE FROM insight_bullet_points 
    WHERE id IN (SELECT id_to_delete FROM ids_to_delete);
    
    GET DIAGNOSTICS removed_bullet_points = ROW_COUNT;
    
    -- Count affected families in bullet points
    WITH duplicates AS (
        SELECT DISTINCT family_id
        FROM (
            SELECT 
                family_id,
                category,
                md5(lower(trim(content))) as content_hash,
                COUNT(*) as dup_count
            FROM insight_bullet_points
            WHERE content IS NOT NULL AND content != ''
            GROUP BY family_id, category, md5(lower(trim(content)))
            HAVING COUNT(*) > 1
        ) dup_families
    )
    SELECT COUNT(*) INTO families_bullet_points FROM duplicates;
    
    -- Clean up contextual_insights duplicates
    WITH duplicates AS (
        SELECT 
            family_id,
            category,
            md5(lower(trim(content))) as content_hash,
            array_agg(id ORDER BY created_at DESC) as ids,
            COUNT(*) as dup_count
        FROM contextual_insights
        WHERE content IS NOT NULL AND content != ''
        GROUP BY family_id, category, md5(lower(trim(content)))
        HAVING COUNT(*) > 1
    ),
    ids_to_delete AS (
        SELECT 
            unnest(ids[2:]) as id_to_delete,
            family_id
        FROM duplicates
    )
    DELETE FROM contextual_insights 
    WHERE id IN (SELECT id_to_delete FROM ids_to_delete);
    
    GET DIAGNOSTICS removed_contextual = ROW_COUNT;
    
    -- Count affected families in contextual insights
    WITH duplicates AS (
        SELECT DISTINCT family_id
        FROM (
            SELECT 
                family_id,
                category,
                md5(lower(trim(content))) as content_hash,
                COUNT(*) as dup_count
            FROM contextual_insights
            WHERE content IS NOT NULL AND content != ''
            GROUP BY family_id, category, md5(lower(trim(content)))
            HAVING COUNT(*) > 1
        ) dup_families
    )
    SELECT COUNT(*) INTO families_contextual FROM duplicates;
    
    -- Return results
    RETURN QUERY
    SELECT 'insight_bullet_points'::text, removed_bullet_points, families_bullet_points
    UNION ALL
    SELECT 'contextual_insights'::text, removed_contextual, families_contextual;
    
    -- Log the cleanup
    RAISE NOTICE 'Duplicate cleanup completed:';
    RAISE NOTICE '  - insight_bullet_points: % duplicates removed from % families', removed_bullet_points, families_bullet_points;
    RAISE NOTICE '  - contextual_insights: % duplicates removed from % families', removed_contextual, families_contextual;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SAFE CLEANUP EXECUTION
-- =====================================================

-- Step 3: Show what will be cleaned up (DRY RUN)
-- Note: Review these results before running the actual cleanup

-- Show bullet points duplicates that would be removed
WITH duplicates AS (
    SELECT 
        family_id,
        category,
        content,
        md5(lower(trim(content))) as content_hash,
        array_agg(id ORDER BY created_at DESC) as ids,
        array_agg(created_at ORDER BY created_at DESC) as dates,
        COUNT(*) as dup_count
    FROM insight_bullet_points
    WHERE content IS NOT NULL AND content != ''
    GROUP BY family_id, category, content, md5(lower(trim(content)))
    HAVING COUNT(*) > 1
),
ids_to_delete AS (
    SELECT 
        unnest(ids[2:]) as id_to_delete,
        unnest(dates[2:]) as date_to_delete,
        family_id,
        category,
        content,
        dup_count
    FROM duplicates
)
SELECT 
    'insight_bullet_points - WOULD DELETE' as action,
    family_id,
    category,
    content,
    id_to_delete,
    date_to_delete,
    dup_count
FROM ids_to_delete
ORDER BY family_id, category, dup_count DESC;

-- Show contextual insights duplicates that would be removed  
WITH duplicates AS (
    SELECT 
        family_id,
        category,
        content,
        md5(lower(trim(content))) as content_hash,
        array_agg(id ORDER BY created_at DESC) as ids,
        array_agg(created_at ORDER BY created_at DESC) as dates,
        COUNT(*) as dup_count
    FROM contextual_insights
    WHERE content IS NOT NULL AND content != ''
    GROUP BY family_id, category, content, md5(lower(trim(content)))
    HAVING COUNT(*) > 1
),
ids_to_delete AS (
    SELECT 
        unnest(ids[2:]) as id_to_delete,
        unnest(dates[2:]) as date_to_delete,
        family_id,
        category,
        content,
        dup_count
    FROM duplicates
)
SELECT 
    'contextual_insights - WOULD DELETE' as action,
    family_id,
    category,
    content,
    id_to_delete,
    date_to_delete,
    dup_count
FROM ids_to_delete
ORDER BY family_id, category, dup_count DESC;

-- =====================================================
-- MANUAL EXECUTION INSTRUCTIONS
-- =====================================================

-- After reviewing the DRY RUN results above, if you're satisfied:
-- 
-- Step 4: Execute the cleanup (UNCOMMENT THE LINE BELOW)
SELECT * FROM cleanup_insight_duplicates();

-- Step 5: Verify cleanup was successful
-- Run the duplicate identification queries again to confirm no duplicates remain:

/*
-- Verification queries (run after cleanup):

SELECT 
    'insight_bullet_points' as table_name,
    family_id,
    category,
    md5(lower(trim(content))) as content_hash,
    content,
    COUNT(*) as duplicate_count
FROM insight_bullet_points
WHERE content IS NOT NULL AND content != ''
GROUP BY family_id, category, md5(lower(trim(content))), content
HAVING COUNT(*) > 1;

SELECT 
    'contextual_insights' as table_name,
    family_id,
    category,
    md5(lower(trim(content))) as content_hash,
    content,
    COUNT(*) as duplicate_count
FROM contextual_insights
WHERE content IS NOT NULL AND content != ''
GROUP BY family_id, category, md5(lower(trim(content))), content
HAVING COUNT(*) > 1;
*/

-- =====================================================
-- BACKUP RECOMMENDATIONS
-- =====================================================

/*
IMPORTANT: Before running this cleanup, consider creating a backup:

-- Create backup tables (OPTIONAL but recommended)
CREATE TABLE insight_bullet_points_backup AS 
SELECT * FROM insight_bullet_points;

CREATE TABLE contextual_insights_backup AS 
SELECT * FROM contextual_insights;

-- After successful cleanup and schema application, you can drop backups:
-- DROP TABLE insight_bullet_points_backup;
-- DROP TABLE contextual_insights_backup;
*/

-- =====================================================
-- EXECUTION SUMMARY
-- =====================================================
-- 
-- DUPLICATE CLEANUP SCRIPT READY
-- 
-- Steps to follow:
-- 1. Review the DRY RUN results above
-- 2. Optionally create backup tables  
-- 3. Uncomment the cleanup execution line
-- 4. Run verification queries
-- 5. Then run add_vector_embeddings_schema.sql
-- ====================================