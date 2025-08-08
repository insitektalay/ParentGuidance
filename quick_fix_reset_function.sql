-- Quick Fix: Alternative reset function that works with current schema
-- This creates a version of reset_family_derived_data that adapts to your current column names

-- First, let's create a flexible version that checks what columns exist
CREATE OR REPLACE FUNCTION reset_family_derived_data_flexible(
    p_family_id UUID,
    p_regen_run_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_deleted_counts JSONB;
    v_guidance_count INT := 0;
    v_insights_count INT := 0;
    v_relevant_count INT := 0;
    v_framework_count INT := 0;
    v_psychologist_count INT := 0;
    v_sql TEXT;
    has_situation_id BOOLEAN;
    situation_column_name TEXT;
BEGIN
    RAISE NOTICE 'Starting flexible family data reset for family: %', p_family_id;
    
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
    
    -- Delete guidance (if we found the right column)
    IF situation_column_name IS NOT NULL THEN
        v_sql := format('DELETE FROM guidance WHERE %I IN (SELECT id FROM situations WHERE family_id = $1)', situation_column_name);
        EXECUTE v_sql USING p_family_id;
        GET DIAGNOSTICS v_guidance_count = ROW_COUNT;
        RAISE NOTICE 'Deleted % guidance records', v_guidance_count;
    END IF;
    
    -- Try to delete from other tables (with error handling)
    BEGIN
        -- Check and delete contextual_insights
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'contextual_insights') THEN
            IF has_situation_id THEN
                DELETE FROM contextual_insights WHERE situation_id IN (SELECT id FROM situations WHERE family_id = p_family_id);
            ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'contextual_insights' AND column_name = 'situationId') THEN
                DELETE FROM contextual_insights WHERE "situationId" IN (SELECT id FROM situations WHERE family_id = p_family_id);
            END IF;
            GET DIAGNOSTICS v_insights_count = ROW_COUNT;
            RAISE NOTICE 'Deleted % contextual insights', v_insights_count;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Could not delete contextual_insights: %', SQLERRM;
    END;
    
    BEGIN
        -- Check and delete relevant_insights
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'relevant_insights') THEN
            IF has_situation_id THEN
                DELETE FROM relevant_insights WHERE situation_id IN (SELECT id FROM situations WHERE family_id = p_family_id);
            ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'relevant_insights' AND column_name = 'situationId') THEN
                DELETE FROM relevant_insights WHERE "situationId" IN (SELECT id FROM situations WHERE family_id = p_family_id);
            END IF;
            GET DIAGNOSTICS v_relevant_count = ROW_COUNT;
            RAISE NOTICE 'Deleted % relevant insights', v_relevant_count;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Could not delete relevant_insights: %', SQLERRM;
    END;
    
    BEGIN
        -- Delete framework recommendations
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'framework_recommendations') THEN
            DELETE FROM framework_recommendations WHERE family_id = p_family_id;
            GET DIAGNOSTICS v_framework_count = ROW_COUNT;
            RAISE NOTICE 'Deleted % framework recommendations', v_framework_count;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Could not delete framework_recommendations: %', SQLERRM;
    END;
    
    BEGIN
        -- Delete psychologist notes
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'psychologist_notes') THEN
            DELETE FROM psychologist_notes WHERE family_id = p_family_id;
            GET DIAGNOSTICS v_psychologist_count = ROW_COUNT;
            RAISE NOTICE 'Deleted % psychologist notes', v_psychologist_count;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Could not delete psychologist_notes: %', SQLERRM;
    END;
    
    -- Return counts
    RETURN jsonb_build_object(
        'guidance_deleted', v_guidance_count,
        'insights_deleted', v_insights_count,
        'relevant_deleted', v_relevant_count,
        'frameworks_deleted', v_framework_count,
        'psychologist_notes_deleted', v_psychologist_count,
        'column_used', COALESCE(situation_column_name, 'none_found')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the original function name as an alias
CREATE OR REPLACE FUNCTION reset_family_derived_data(
    p_family_id UUID,
    p_regen_run_id UUID
) RETURNS JSONB AS $$
BEGIN
    RETURN reset_family_derived_data_flexible(p_family_id, p_regen_run_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION reset_family_derived_data TO authenticated;
GRANT EXECUTE ON FUNCTION reset_family_derived_data_flexible TO authenticated;

-- Test the function
SELECT 'Quick fix function created successfully. Test with a sample family_id to verify.' as status;