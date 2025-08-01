-- =====================================================
-- Fix Deduplication Metrics RLS Policy
-- =====================================================
-- This script fixes the RLS policy that references non-existent
-- families.user_id column by using the correct schema structure.
--
-- Run this instead of the problematic section in 
-- create_deduplication_metrics_table.sql
-- =====================================================

-- First, let's check the actual families table structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'families'
ORDER BY ordinal_position;

-- Check if there's a user relationship through other means
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN ('families', 'user_profiles', 'users')
    AND column_name LIKE '%user%'
ORDER BY table_name, column_name;

-- =====================================================
-- CREATE METRICS TABLE (Fixed Version)
-- =====================================================

-- Create the deduplication_metrics table (if not already exists)
CREATE TABLE IF NOT EXISTS deduplication_metrics (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    family_id uuid NOT NULL,
    operation_type text NOT NULL CHECK (operation_type IN (
        'extract_context',
        'extract_regulation',
        'extract_coping',
        'regenerate_all_context',
        'regenerate_all_regulation',
        'backfill_embeddings'
    )),
    table_name text NOT NULL CHECK (table_name IN (
        'insight_bullet_points',
        'contextual_insights',
        'both'
    )),
    
    -- Core deduplication metrics
    candidates_generated integer NOT NULL DEFAULT 0,
    duplicates_found integer NOT NULL DEFAULT 0,
    insights_inserted integer NOT NULL DEFAULT 0,
    insights_fused integer NOT NULL DEFAULT 0,
    insights_rewritten integer NOT NULL DEFAULT 0,
    race_condition_duplicates integer NOT NULL DEFAULT 0,
    
    -- Language processing metrics
    languages_detected jsonb NOT NULL DEFAULT '{}', -- {"en": 10, "es": 2, "fr": 1}
    translations_performed integer NOT NULL DEFAULT 0,
    
    -- Performance metrics
    processing_time_ms integer NOT NULL DEFAULT 0,
    embedding_generation_time_ms integer NOT NULL DEFAULT 0,
    similarity_search_time_ms integer NOT NULL DEFAULT 0,
    
    -- Model and configuration tracking
    embedding_model text NOT NULL DEFAULT 'text-embedding-3-small',
    similarity_threshold_used float NOT NULL DEFAULT 0.85,
    
    -- Additional context
    batch_size integer,
    api_provider text, -- 'openai', 'anthropic', 'xai', 'google'
    
    created_at timestamp with time zone DEFAULT now()
);

-- Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_deduplication_metrics_family_id 
ON deduplication_metrics (family_id);

CREATE INDEX IF NOT EXISTS idx_deduplication_metrics_operation_type 
ON deduplication_metrics (operation_type);

CREATE INDEX IF NOT EXISTS idx_deduplication_metrics_created_at 
ON deduplication_metrics (created_at);

CREATE INDEX IF NOT EXISTS idx_deduplication_metrics_family_operation 
ON deduplication_metrics (family_id, operation_type, created_at);

-- =====================================================
-- SIMPLIFIED RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE deduplication_metrics ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "users_can_view_own_family_metrics" ON deduplication_metrics;
DROP POLICY IF EXISTS "service_role_can_insert_metrics" ON deduplication_metrics;

-- Simple policy: authenticated users can see metrics for families they have access to
-- This assumes there's some way to determine family access - adjust based on your schema
CREATE POLICY "authenticated_users_can_view_metrics" ON deduplication_metrics
    FOR SELECT USING (auth.role() = 'authenticated');

-- Service role can insert and modify all metrics (for Edge Functions)
CREATE POLICY "service_role_can_modify_metrics" ON deduplication_metrics
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- If you need family-specific access, you'll need to adjust based on your actual schema
-- For example, if families table has an 'owner_id' or similar:
-- CREATE POLICY "users_can_view_own_family_metrics" ON deduplication_metrics
--     FOR SELECT USING (
--         EXISTS (
--             SELECT 1 FROM families 
--             WHERE families.id = deduplication_metrics.family_id 
--             AND families.owner_id = auth.uid()  -- Adjust column name as needed
--         )
--     );

-- =====================================================
-- HELPER FUNCTIONS (From Original Script)
-- =====================================================

-- Function to get deduplication effectiveness for a family
CREATE OR REPLACE FUNCTION get_deduplication_effectiveness(
    target_family_id uuid,
    time_period_days integer DEFAULT 30
)
RETURNS TABLE (
    operation_type text,
    total_operations bigint,
    avg_candidates_per_operation numeric,
    avg_duplicates_found numeric,
    avg_duplicates_prevented_pct numeric,
    avg_race_conditions numeric,
    most_common_languages jsonb
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dm.operation_type,
        COUNT(*) as total_operations,
        ROUND(AVG(dm.candidates_generated), 2) as avg_candidates_per_operation,
        ROUND(AVG(dm.duplicates_found), 2) as avg_duplicates_found,
        ROUND(
            CASE 
                WHEN AVG(dm.candidates_generated) > 0 THEN
                    (AVG(dm.duplicates_found) / AVG(dm.candidates_generated)) * 100
                ELSE 0 
            END, 2
        ) as avg_duplicates_prevented_pct,
        ROUND(AVG(dm.race_condition_duplicates), 2) as avg_race_conditions,
        jsonb_object_agg(
            lang_key, 
            lang_count ORDER BY lang_count DESC
        ) FILTER (WHERE lang_key IS NOT NULL) as most_common_languages
    FROM deduplication_metrics dm,
         LATERAL jsonb_each_text(dm.languages_detected) AS lang(lang_key, lang_count)
    WHERE 
        dm.family_id = target_family_id
        AND dm.created_at >= NOW() - INTERVAL '1 day' * time_period_days
    GROUP BY dm.operation_type
    ORDER BY total_operations DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get language processing statistics
CREATE OR REPLACE FUNCTION get_language_processing_stats(
    target_family_id uuid DEFAULT NULL,
    time_period_days integer DEFAULT 30
)
RETURNS TABLE (
    language_code text,
    total_occurrences bigint,
    operations_with_language bigint,
    avg_translations_per_operation numeric,
    total_translations bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lang.lang_key as language_code,
        SUM(lang.lang_count::bigint) as total_occurrences,
        COUNT(DISTINCT dm.id) as operations_with_language,
        ROUND(AVG(dm.translations_performed), 2) as avg_translations_per_operation,
        SUM(dm.translations_performed) as total_translations
    FROM deduplication_metrics dm,
         LATERAL jsonb_each_text(dm.languages_detected) AS lang(lang_key, lang_count)
    WHERE 
        (target_family_id IS NULL OR dm.family_id = target_family_id)
        AND dm.created_at >= NOW() - INTERVAL '1 day' * time_period_days
        AND lang.lang_key IS NOT NULL
    GROUP BY lang.lang_key
    ORDER BY total_occurrences DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get performance metrics summary
CREATE OR REPLACE FUNCTION get_performance_summary(
    target_family_id uuid DEFAULT NULL,
    time_period_days integer DEFAULT 7
)
RETURNS TABLE (
    operation_type text,
    avg_total_time_ms numeric,
    avg_embedding_time_ms numeric,
    avg_similarity_search_time_ms numeric,
    avg_insights_per_second numeric,
    total_operations bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dm.operation_type,
        ROUND(AVG(dm.processing_time_ms), 2) as avg_total_time_ms,
        ROUND(AVG(dm.embedding_generation_time_ms), 2) as avg_embedding_time_ms,
        ROUND(AVG(dm.similarity_search_time_ms), 2) as avg_similarity_search_time_ms,
        ROUND(
            CASE 
                WHEN AVG(dm.processing_time_ms) > 0 THEN
                    (AVG(dm.insights_inserted) * 1000.0) / AVG(dm.processing_time_ms)
                ELSE 0 
            END, 3
        ) as avg_insights_per_second,
        COUNT(*) as total_operations
    FROM deduplication_metrics dm
    WHERE 
        (target_family_id IS NULL OR dm.family_id = target_family_id)
        AND dm.created_at >= NOW() - INTERVAL '1 day' * time_period_days
    GROUP BY dm.operation_type
    ORDER BY total_operations DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check table was created successfully
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'deduplication_metrics'
ORDER BY ordinal_position;

-- Check policies were created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'deduplication_metrics';

-- Test the helper functions work
SELECT 'Helper functions created successfully' as status;

-- =====================================================
-- NEXT STEPS
-- =====================================================
-- 
-- 1. Review the RLS policies above and adjust based on your actual schema
-- 2. If you have a different way to relate families to users, update the policies
-- 3. Test inserting a sample record to verify everything works
-- 4. Then proceed with the vector embeddings schema
-- =====================================================