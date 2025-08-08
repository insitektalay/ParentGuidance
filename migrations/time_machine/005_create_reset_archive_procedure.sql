-- Create a procedure to archive and reset derived data for time machine runs
CREATE OR REPLACE FUNCTION reset_family_derived_data(
    p_family_id UUID,
    p_regen_run_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_deleted_counts JSONB;
    v_guidance_count INT;
    v_insights_count INT;
    v_relevant_count INT;
    v_framework_count INT;
    v_psychologist_count INT;
BEGIN
    -- Delete guidance
    DELETE FROM guidance 
    WHERE situation_id IN (
        SELECT id FROM situations WHERE family_id = p_family_id
    );
    GET DIAGNOSTICS v_guidance_count = ROW_COUNT;
    
    -- Delete relevant insights
    DELETE FROM relevant_insights
    WHERE situation_id IN (
        SELECT id FROM situations WHERE family_id = p_family_id
    );
    GET DIAGNOSTICS v_relevant_count = ROW_COUNT;
    
    -- Delete contextual insights
    DELETE FROM contextual_insights
    WHERE situation_id IN (
        SELECT id FROM situations WHERE family_id = p_family_id
    );
    GET DIAGNOSTICS v_insights_count = ROW_COUNT;
    
    -- Delete regulation insights
    DELETE FROM insight_bullet_points
    WHERE situation_id IN (
        SELECT id FROM situations WHERE family_id = p_family_id
    );
    
    -- Delete framework recommendations
    DELETE FROM framework_recommendations
    WHERE family_id = p_family_id;
    GET DIAGNOSTICS v_framework_count = ROW_COUNT;
    
    -- Delete psychologist notes
    DELETE FROM psychologist_notes
    WHERE family_id = p_family_id;
    GET DIAGNOSTICS v_psychologist_count = ROW_COUNT;
    
    -- Delete deduplication metrics
    DELETE FROM deduplication_metrics
    WHERE situation_id IN (
        SELECT id FROM situations WHERE family_id = p_family_id
    );
    
    -- Clear embeddings
    UPDATE contextual_insights 
    SET embedding = NULL 
    WHERE situation_id IN (
        SELECT id FROM situations WHERE family_id = p_family_id
    );
    
    UPDATE insight_bullet_points 
    SET embedding = NULL 
    WHERE situation_id IN (
        SELECT id FROM situations WHERE family_id = p_family_id
    );
    
    -- Return counts
    RETURN jsonb_build_object(
        'guidance_deleted', v_guidance_count,
        'insights_deleted', v_insights_count,
        'relevant_deleted', v_relevant_count,
        'frameworks_deleted', v_framework_count,
        'psychologist_notes_deleted', v_psychologist_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION reset_family_derived_data TO authenticated;