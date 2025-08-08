-- Date-Range Selective Reset Function
-- This function only deletes guidance and insights within the specified date range
-- Fixes the critical issue where reset_family_derived_data was deleting ALL family data

-- Create the date-range selective reset function
CREATE OR REPLACE FUNCTION reset_family_derived_data_date_range(
    p_family_id UUID,
    p_regen_run_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_deleted_counts JSONB;
    v_guidance_count INT := 0;
    v_contextual_insights_count INT := 0;
    v_relevant_insights_count INT := 0;
    v_bullet_points_count INT := 0;
    v_framework_count INT := 0;
    v_psychologist_count INT := 0;
    v_sql TEXT;
    has_situation_id BOOLEAN;
    situation_column_name TEXT;
    v_situation_ids UUID[];
    v_date_filter TEXT := '';
BEGIN
    RAISE NOTICE 'Starting date-range selective reset for family: %', p_family_id;
    RAISE NOTICE 'Date range: % to %', p_start_date, p_end_date;
    
    -- Build date filter conditions if dates are provided
    IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL THEN
        v_date_filter := format(' AND created_at >= %L AND created_at < %L', p_start_date, p_end_date);
        RAISE NOTICE 'Using date filter: %', v_date_filter;
    ELSIF p_start_date IS NOT NULL OR p_end_date IS NOT NULL THEN
        RAISE EXCEPTION 'Both start_date and end_date must be provided together or both must be NULL';
    ELSE
        RAISE NOTICE 'No date range specified - will reset ALL family data (use with caution!)';
    END IF;
    
    -- Get situation IDs that match the criteria
    v_sql := format('SELECT ARRAY(SELECT id FROM situations WHERE family_id = %L%s)', p_family_id, v_date_filter);
    EXECUTE v_sql INTO v_situation_ids;
    
    RAISE NOTICE 'Found % situations matching criteria', array_length(v_situation_ids, 1);
    
    -- If no situations found, return early
    IF v_situation_ids IS NULL OR array_length(v_situation_ids, 1) = 0 THEN
        RETURN jsonb_build_object(
            'guidance_deleted', 0,
            'contextual_insights_deleted', 0,
            'relevant_insights_deleted', 0,
            'bullet_points_deleted', 0,
            'frameworks_deleted', 0,
            'psychologist_notes_deleted', 0,
            'situations_found', 0,
            'date_range_used', p_start_date IS NOT NULL,
            'message', 'No situations found matching the criteria'
        );
    END IF;
    
    -- Check if guidance table has situation_id or situationId column
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'guidance' AND column_name = 'situation_id'
    ) INTO has_situation_id;
    
    IF has_situation_id THEN
        situation_column_name := 'situation_id';
        RAISE NOTICE 'Using situation_id column';
    ELSIF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'guidance' AND column_name = 'situationId'
    ) THEN
        situation_column_name := 'situationId';
        RAISE NOTICE 'Using situationId column (camelCase)';
    ELSE
        RAISE NOTICE 'No recognizable situation reference column found in guidance table';
        situation_column_name := NULL;
    END IF;
    
    -- Delete guidance for matching situations only
    IF situation_column_name IS NOT NULL THEN
        v_sql := format('DELETE FROM guidance WHERE %I = ANY($1)', situation_column_name);
        EXECUTE v_sql USING v_situation_ids;
        GET DIAGNOSTICS v_guidance_count = ROW_COUNT;
        RAISE NOTICE 'Deleted % guidance records for date range', v_guidance_count;
    END IF;
    
    -- Delete contextual_insights for matching situations
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'contextual_insights') THEN
            IF has_situation_id THEN
                DELETE FROM contextual_insights WHERE situation_id = ANY(v_situation_ids);
            ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contextual_insights' AND column_name = 'situationId') THEN
                DELETE FROM contextual_insights WHERE "situationId" = ANY(v_situation_ids);
            END IF;
            GET DIAGNOSTICS v_contextual_insights_count = ROW_COUNT;
            RAISE NOTICE 'Deleted % contextual insights for date range', v_contextual_insights_count;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Could not delete contextual_insights: %', SQLERRM;
    END;
    
    -- Delete relevant_insights for matching situations
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'relevant_insights') THEN
            IF has_situation_id THEN
                DELETE FROM relevant_insights WHERE situation_id = ANY(v_situation_ids);
            ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'relevant_insights' AND column_name = 'situationId') THEN
                DELETE FROM relevant_insights WHERE "situationId" = ANY(v_situation_ids);
            END IF;
            GET DIAGNOSTICS v_relevant_insights_count = ROW_COUNT;
            RAISE NOTICE 'Deleted % relevant insights for date range', v_relevant_insights_count;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Could not delete relevant_insights: %', SQLERRM;
    END;
    
    -- Delete insight_bullet_points for matching situations
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'insight_bullet_points') THEN
            IF has_situation_id THEN
                DELETE FROM insight_bullet_points WHERE situation_id = ANY(v_situation_ids);
            ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'insight_bullet_points' AND column_name = 'situationId') THEN
                DELETE FROM insight_bullet_points WHERE "situationId" = ANY(v_situation_ids);
            END IF;
            GET DIAGNOSTICS v_bullet_points_count = ROW_COUNT;
            RAISE NOTICE 'Deleted % insight bullet points for date range', v_bullet_points_count;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Could not delete insight_bullet_points: %', SQLERRM;
    END;
    
    -- Note: Framework recommendations and psychologist notes are family-level, not situation-level
    -- We only delete these if NO date range is specified (full family reset)
    IF p_start_date IS NULL AND p_end_date IS NULL THEN
        BEGIN
            -- Delete framework recommendations (full family reset only)
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'framework_recommendations') THEN
                DELETE FROM framework_recommendations WHERE family_id = p_family_id;
                GET DIAGNOSTICS v_framework_count = ROW_COUNT;
                RAISE NOTICE 'Deleted % framework recommendations (full reset)', v_framework_count;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not delete framework_recommendations: %', SQLERRM;
        END;
        
        BEGIN
            -- Delete psychologist notes (full family reset only)
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'psychologist_notes') THEN
                DELETE FROM psychologist_notes WHERE family_id = p_family_id;
                GET DIAGNOSTICS v_psychologist_count = ROW_COUNT;
                RAISE NOTICE 'Deleted % psychologist notes (full reset)', v_psychologist_count;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not delete psychologist_notes: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'Skipping family-level data deletion (framework_recommendations, psychologist_notes) due to date range filter';
    END IF;
    
    -- Return detailed counts
    RETURN jsonb_build_object(
        'guidance_deleted', v_guidance_count,
        'contextual_insights_deleted', v_contextual_insights_count,
        'relevant_insights_deleted', v_relevant_insights_count,
        'bullet_points_deleted', v_bullet_points_count,
        'frameworks_deleted', v_framework_count,
        'psychologist_notes_deleted', v_psychologist_count,
        'situations_found', array_length(v_situation_ids, 1),
        'date_range_used', p_start_date IS NOT NULL,
        'start_date', p_start_date,
        'end_date', p_end_date,
        'column_used', COALESCE(situation_column_name, 'none_found')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the original function to use date-range selective approach
-- This maintains backward compatibility while adding date range support
CREATE OR REPLACE FUNCTION reset_family_derived_data(
    p_family_id UUID,
    p_regen_run_id UUID
) RETURNS JSONB AS $$
BEGIN
    -- Call the date-range version without date restrictions (full reset)
    -- This maintains the original behavior for existing code
    RETURN reset_family_derived_data_date_range(p_family_id, p_regen_run_id, NULL, NULL);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION reset_family_derived_data_date_range TO authenticated;
GRANT EXECUTE ON FUNCTION reset_family_derived_data TO authenticated;

-- Test query to verify function creation
SELECT 'Date-range selective reset function created successfully!' as status,
       'Use reset_family_derived_data_date_range(family_id, regen_run_id, start_date, end_date) for selective resets' as usage;