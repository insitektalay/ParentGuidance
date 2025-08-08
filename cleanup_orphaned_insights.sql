-- Orphaned Insight Cleanup Script
-- This script identifies and removes insights that have no corresponding guidance records

-- Function to find orphaned insights
CREATE OR REPLACE FUNCTION find_orphaned_insights(p_family_id UUID DEFAULT NULL)
RETURNS TABLE (
    table_name TEXT,
    orphaned_count BIGINT,
    sample_ids UUID[]
) AS $$
BEGIN
    -- Check contextual_insights
    RETURN QUERY
    SELECT 
        'contextual_insights'::TEXT,
        COUNT(*)::BIGINT,
        ARRAY_AGG(ci.id ORDER BY ci.created_at DESC LIMIT 10)::UUID[]
    FROM contextual_insights ci
    LEFT JOIN guidance g ON (
        ci.situation_id = g.situation_id OR 
        ci."situationId" = g."situationId" OR
        ci.situation_id::TEXT = g.situation_id::TEXT OR
        ci."situationId"::TEXT = g."situationId"::TEXT
    )
    WHERE g.id IS NULL
    AND (p_family_id IS NULL OR ci.family_id = p_family_id);
    
    -- Check relevant_insights
    RETURN QUERY
    SELECT 
        'relevant_insights'::TEXT,
        COUNT(*)::BIGINT,
        ARRAY_AGG(ri.id ORDER BY ri.created_at DESC LIMIT 10)::UUID[]
    FROM relevant_insights ri
    LEFT JOIN guidance g ON (
        ri.situation_id = g.situation_id OR 
        ri."situationId" = g."situationId" OR
        ri.situation_id::TEXT = g.situation_id::TEXT OR
        ri."situationId"::TEXT = g."situationId"::TEXT
    )
    WHERE g.id IS NULL
    AND (p_family_id IS NULL OR EXISTS (
        SELECT 1 FROM situations s 
        WHERE (s.id = ri.situation_id OR s.id::TEXT = ri."situationId"::TEXT)
        AND s.family_id = p_family_id
    ));
    
    -- Check insight_bullet_points
    RETURN QUERY
    SELECT 
        'insight_bullet_points'::TEXT,
        COUNT(*)::BIGINT,
        ARRAY_AGG(ibp.id ORDER BY ibp.created_at DESC LIMIT 10)::UUID[]
    FROM insight_bullet_points ibp
    LEFT JOIN guidance g ON (
        ibp.situation_id = g.situation_id OR 
        ibp."situationId" = g."situationId" OR
        ibp.situation_id::TEXT = g.situation_id::TEXT OR
        ibp."situationId"::TEXT = g."situationId"::TEXT
    )
    WHERE g.id IS NULL
    AND (p_family_id IS NULL OR EXISTS (
        SELECT 1 FROM situations s 
        WHERE (s.id = ibp.situation_id OR s.id::TEXT = ibp."situationId"::TEXT)
        AND s.family_id = p_family_id
    ));
END;
$$ LANGUAGE plpgsql;

-- Function to clean up orphaned insights
CREATE OR REPLACE FUNCTION cleanup_orphaned_insights(
    p_family_id UUID DEFAULT NULL,
    p_dry_run BOOLEAN DEFAULT TRUE
) RETURNS JSONB AS $$
DECLARE
    v_deleted_counts JSONB;
    v_contextual_count INT := 0;
    v_relevant_count INT := 0;
    v_bullet_count INT := 0;
    v_total_count INT := 0;
BEGIN
    IF p_dry_run THEN
        RAISE NOTICE 'DRY RUN MODE - No data will be deleted';
    END IF;
    
    -- Find orphaned records first
    CREATE TEMP TABLE orphaned_records AS
    SELECT * FROM find_orphaned_insights(p_family_id);
    
    -- Log what we found
    FOR r IN SELECT * FROM orphaned_records LOOP
        RAISE NOTICE 'Found % orphaned records in %', r.orphaned_count, r.table_name;
    END LOOP;
    
    IF NOT p_dry_run THEN
        -- Delete orphaned contextual_insights
        WITH deleted AS (
            DELETE FROM contextual_insights ci
            WHERE NOT EXISTS (
                SELECT 1 FROM guidance g 
                WHERE ci.situation_id = g.situation_id 
                   OR ci."situationId" = g."situationId"
                   OR ci.situation_id::TEXT = g.situation_id::TEXT 
                   OR ci."situationId"::TEXT = g."situationId"::TEXT
            )
            AND (p_family_id IS NULL OR ci.family_id = p_family_id)
            RETURNING 1
        )
        SELECT COUNT(*) INTO v_contextual_count FROM deleted;
        
        -- Delete orphaned relevant_insights
        WITH deleted AS (
            DELETE FROM relevant_insights ri
            WHERE NOT EXISTS (
                SELECT 1 FROM guidance g 
                WHERE ri.situation_id = g.situation_id 
                   OR ri."situationId" = g."situationId"
                   OR ri.situation_id::TEXT = g.situation_id::TEXT 
                   OR ri."situationId"::TEXT = g."situationId"::TEXT
            )
            AND (p_family_id IS NULL OR EXISTS (
                SELECT 1 FROM situations s 
                WHERE (s.id = ri.situation_id OR s.id::TEXT = ri."situationId"::TEXT)
                AND s.family_id = p_family_id
            ))
            RETURNING 1
        )
        SELECT COUNT(*) INTO v_relevant_count FROM deleted;
        
        -- Delete orphaned insight_bullet_points
        WITH deleted AS (
            DELETE FROM insight_bullet_points ibp
            WHERE NOT EXISTS (
                SELECT 1 FROM guidance g 
                WHERE ibp.situation_id = g.situation_id 
                   OR ibp."situationId" = g."situationId"
                   OR ibp.situation_id::TEXT = g.situation_id::TEXT 
                   OR ibp."situationId"::TEXT = g."situationId"::TEXT
            )
            AND (p_family_id IS NULL OR EXISTS (
                SELECT 1 FROM situations s 
                WHERE (s.id = ibp.situation_id OR s.id::TEXT = ibp."situationId"::TEXT)
                AND s.family_id = p_family_id
            ))
            RETURNING 1
        )
        SELECT COUNT(*) INTO v_bullet_count FROM deleted;
        
        v_total_count := v_contextual_count + v_relevant_count + v_bullet_count;
        RAISE NOTICE 'Cleanup complete: Deleted % total orphaned insights', v_total_count;
    END IF;
    
    -- Clean up temp table
    DROP TABLE orphaned_records;
    
    -- Return summary
    RETURN jsonb_build_object(
        'dry_run', p_dry_run,
        'family_id', p_family_id,
        'contextual_insights_deleted', v_contextual_count,
        'relevant_insights_deleted', v_relevant_count,
        'insight_bullet_points_deleted', v_bullet_count,
        'total_deleted', v_total_count,
        'timestamp', NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION find_orphaned_insights TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_orphaned_insights TO authenticated;

-- Example usage:
-- Dry run to see what would be deleted:
-- SELECT * FROM cleanup_orphaned_insights(NULL, TRUE);
-- 
-- Actually clean up all orphaned insights:
-- SELECT * FROM cleanup_orphaned_insights(NULL, FALSE);
-- 
-- Clean up for a specific family only:
-- SELECT * FROM cleanup_orphaned_insights('your-family-id-here'::UUID, FALSE);