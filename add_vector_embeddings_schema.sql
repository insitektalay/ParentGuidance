-- =====================================================
-- Add Vector Embedding Support to Insights Tables
-- =====================================================
-- This script adds pgvector support and embedding columns to both
-- insight_bullet_points and contextual_insights tables for 
-- multilingual deduplication using semantic similarity.
--
-- Run this script in your Supabase SQL Editor AFTER creating
-- the settings table (run create_settings_table.sql first)
-- =====================================================

-- Step 1: Enable pgvector extension if not already enabled
CREATE EXTENSION IF NOT EXISTS vector;

-- Verify pgvector is available
SELECT 
    name, 
    default_version, 
    installed_version 
FROM pg_available_extensions 
WHERE name = 'vector';

-- Step 2: Get current embedding dimension from settings
DO $$
DECLARE
    current_dimension INTEGER;
BEGIN
    -- Get the current embedding dimension from settings
    SELECT value::INTEGER INTO current_dimension 
    FROM settings 
    WHERE key = 'current_embedding_dimension';
    
    IF current_dimension IS NULL THEN
        RAISE EXCEPTION 'Embedding dimension not found in settings. Run create_settings_table.sql first.';
    END IF;
    
    RAISE NOTICE 'Using embedding dimension: %', current_dimension;
END $$;

-- Step 3: Add embedding columns to insight_bullet_points table
ALTER TABLE insight_bullet_points 
ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- Add column comment
COMMENT ON COLUMN insight_bullet_points.embedding IS 
'Vector embedding of the insight content (in English) for semantic similarity matching and deduplication. Generated using OpenAI text-embedding-3-small model.';

-- Step 4: Add embedding columns to contextual_insights table  
ALTER TABLE contextual_insights 
ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- Add column comment
COMMENT ON COLUMN contextual_insights.embedding IS 
'Vector embedding of the insight content (in English) for semantic similarity matching and deduplication. Generated using OpenAI text-embedding-3-small model.';

-- Step 5: Add partial unique indexes for literal duplicate prevention
-- These catch exact duplicates before they reach the vector similarity check

-- For insight_bullet_points
CREATE UNIQUE INDEX IF NOT EXISTS idx_bullet_points_unique_content
ON insight_bullet_points (family_id, category, md5(lower(trim(content))))
WHERE content IS NOT NULL AND content != '';

-- For contextual_insights  
CREATE UNIQUE INDEX IF NOT EXISTS idx_contextual_insights_unique_content
ON contextual_insights (family_id, category, md5(lower(trim(content))))
WHERE content IS NOT NULL AND content != '';

-- Step 6: Add metadata columns for tracking embedding generation
ALTER TABLE insight_bullet_points 
ADD COLUMN IF NOT EXISTS embedding_model TEXT DEFAULT 'text-embedding-3-small',
ADD COLUMN IF NOT EXISTS embedding_language TEXT DEFAULT 'en',
ADD COLUMN IF NOT EXISTS was_translated BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS embedding_generated_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE contextual_insights 
ADD COLUMN IF NOT EXISTS embedding_model TEXT DEFAULT 'text-embedding-3-small', 
ADD COLUMN IF NOT EXISTS embedding_language TEXT DEFAULT 'en',
ADD COLUMN IF NOT EXISTS was_translated BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS embedding_generated_at TIMESTAMP WITH TIME ZONE;

-- Add comments for metadata columns
COMMENT ON COLUMN insight_bullet_points.embedding_model IS 'AI model used to generate the embedding (e.g., text-embedding-3-small)';
COMMENT ON COLUMN insight_bullet_points.embedding_language IS 'Language the embedding was generated from (always en for consistency)';
COMMENT ON COLUMN insight_bullet_points.was_translated IS 'Whether the original content was translated to English before embedding';
COMMENT ON COLUMN insight_bullet_points.embedding_generated_at IS 'Timestamp when the embedding was generated';

COMMENT ON COLUMN contextual_insights.embedding_model IS 'AI model used to generate the embedding (e.g., text-embedding-3-small)';
COMMENT ON COLUMN contextual_insights.embedding_language IS 'Language the embedding was generated from (always en for consistency)';
COMMENT ON COLUMN contextual_insights.was_translated IS 'Whether the original content was translated to English before embedding';
COMMENT ON COLUMN contextual_insights.embedding_generated_at IS 'Timestamp when the embedding was generated';

-- Step 7: Create vector similarity indexes using IVFFlat
-- Note: These indexes will be created after we have some embedded data
-- IVFFlat requires training data, so we'll create them later or use approximate values

-- Create function to add vector indexes when data is available
CREATE OR REPLACE FUNCTION create_vector_similarity_indexes()
RETURNS void AS $$
DECLARE
    bullet_points_count INTEGER;
    contextual_count INTEGER;
BEGIN
    -- Check if we have enough embedded data to create indexes
    SELECT COUNT(*) INTO bullet_points_count 
    FROM insight_bullet_points 
    WHERE embedding IS NOT NULL;
    
    SELECT COUNT(*) INTO contextual_count 
    FROM contextual_insights 
    WHERE embedding IS NOT NULL;
    
    RAISE NOTICE 'Found % bullet points and % contextual insights with embeddings', 
                 bullet_points_count, contextual_count;
    
    -- Create indexes if we have sufficient data (at least 100 rows recommended for IVFFlat)
    IF bullet_points_count >= 100 THEN
        -- Calculate lists parameter (typically sqrt of row count, capped at 1000)
        EXECUTE format('CREATE INDEX IF NOT EXISTS idx_bullet_points_embedding 
                       ON insight_bullet_points 
                       USING ivfflat (embedding vector_cosine_ops) 
                       WITH (lists = %s)', 
                       LEAST(1000, GREATEST(10, sqrt(bullet_points_count)::INTEGER)));
        RAISE NOTICE 'Created IVFFlat index for insight_bullet_points';
    ELSE
        -- Use simpler index for small datasets
        CREATE INDEX IF NOT EXISTS idx_bullet_points_embedding_simple
        ON insight_bullet_points (embedding);
        RAISE NOTICE 'Created simple index for insight_bullet_points (insufficient data for IVFFlat)';
    END IF;
    
    IF contextual_count >= 100 THEN
        EXECUTE format('CREATE INDEX IF NOT EXISTS idx_contextual_insights_embedding 
                       ON contextual_insights 
                       USING ivfflat (embedding vector_cosine_ops) 
                       WITH (lists = %s)', 
                       LEAST(1000, GREATEST(10, sqrt(contextual_count)::INTEGER)));
        RAISE NOTICE 'Created IVFFlat index for contextual_insights';
    ELSE
        -- Use simpler index for small datasets
        CREATE INDEX IF NOT EXISTS idx_contextual_insights_embedding_simple
        ON contextual_insights (embedding);
        RAISE NOTICE 'Created simple index for contextual_insights (insufficient data for IVFFlat)';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Run the index creation function
SELECT create_vector_similarity_indexes();

-- Step 8: Create helper functions for vector similarity operations

-- Function to find similar insights in bullet_points table
CREATE OR REPLACE FUNCTION find_similar_bullet_points(
    target_embedding vector(1536),
    family_id_filter uuid,
    category_filter text,
    similarity_threshold float DEFAULT 0.90,
    max_results integer DEFAULT 20
)
RETURNS TABLE (
    id uuid,
    content text,
    category text,
    similarity_score float,
    was_translated boolean,
    created_at timestamp with time zone
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bp.id,
        bp.content,
        bp.category,
        1 - (bp.embedding <=> target_embedding) as similarity_score,
        bp.was_translated,
        bp.created_at
    FROM insight_bullet_points bp
    WHERE 
        bp.family_id = family_id_filter
        AND bp.category = category_filter
        AND bp.embedding IS NOT NULL
        AND 1 - (bp.embedding <=> target_embedding) >= similarity_threshold
    ORDER BY bp.embedding <=> target_embedding ASC
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Function to find similar insights in contextual_insights table
CREATE OR REPLACE FUNCTION find_similar_contextual_insights(
    target_embedding vector(1536),
    family_id_filter uuid,
    category_filter text,
    similarity_threshold float DEFAULT 0.85,
    max_results integer DEFAULT 20
)
RETURNS TABLE (
    id uuid,
    content text,
    category text,
    subcategory text,
    similarity_score float,
    was_translated boolean,
    created_at timestamp with time zone
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id,
        ci.content,
        ci.category,
        ci.subcategory,
        1 - (ci.embedding <=> target_embedding) as similarity_score,
        ci.was_translated,
        ci.created_at
    FROM contextual_insights ci
    WHERE 
        ci.family_id = family_id_filter
        AND ci.category = category_filter
        AND ci.embedding IS NOT NULL
        AND 1 - (ci.embedding <=> target_embedding) >= similarity_threshold
    ORDER BY ci.embedding <=> target_embedding ASC
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- Step 9: Create triggers to ensure embedding_generated_at is set when embedding is updated
CREATE OR REPLACE FUNCTION update_embedding_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    -- Only update timestamp if embedding actually changed
    IF OLD.embedding IS DISTINCT FROM NEW.embedding AND NEW.embedding IS NOT NULL THEN
        NEW.embedding_generated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers to both tables
CREATE TRIGGER bullet_points_embedding_timestamp
    BEFORE UPDATE ON insight_bullet_points
    FOR EACH ROW
    EXECUTE FUNCTION update_embedding_timestamp();

CREATE TRIGGER contextual_insights_embedding_timestamp
    BEFORE UPDATE ON contextual_insights
    FOR EACH ROW
    EXECUTE FUNCTION update_embedding_timestamp();

-- Step 10: Verify the schema changes
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name IN ('insight_bullet_points', 'contextual_insights')
    AND column_name IN ('embedding', 'embedding_model', 'embedding_language', 'was_translated', 'embedding_generated_at')
ORDER BY table_name, column_name;

-- Check indexes were created
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN ('insight_bullet_points', 'contextual_insights')
    AND indexname LIKE '%embedding%'
ORDER BY tablename, indexname;

-- =====================================================
-- ROLLBACK INSTRUCTIONS
-- =====================================================
-- If you need to remove the vector embedding columns:
-- 
-- DROP TRIGGER IF EXISTS bullet_points_embedding_timestamp ON insight_bullet_points;
-- DROP TRIGGER IF EXISTS contextual_insights_embedding_timestamp ON contextual_insights;
-- DROP FUNCTION IF EXISTS update_embedding_timestamp();
-- DROP FUNCTION IF EXISTS find_similar_bullet_points(vector(1536), uuid, text, float, integer);
-- DROP FUNCTION IF EXISTS find_similar_contextual_insights(vector(1536), uuid, text, float, integer);
-- DROP FUNCTION IF EXISTS create_vector_similarity_indexes();
-- 
-- DROP INDEX IF EXISTS idx_bullet_points_embedding;
-- DROP INDEX IF EXISTS idx_contextual_insights_embedding;
-- DROP INDEX IF EXISTS idx_bullet_points_embedding_simple;
-- DROP INDEX IF EXISTS idx_contextual_insights_embedding_simple;
-- DROP INDEX IF EXISTS idx_bullet_points_unique_content;
-- DROP INDEX IF EXISTS idx_contextual_insights_unique_content;
-- 
-- ALTER TABLE insight_bullet_points 
-- DROP COLUMN IF EXISTS embedding,
-- DROP COLUMN IF EXISTS embedding_model,
-- DROP COLUMN IF EXISTS embedding_language,
-- DROP COLUMN IF EXISTS was_translated,
-- DROP COLUMN IF EXISTS embedding_generated_at;
-- 
-- ALTER TABLE contextual_insights 
-- DROP COLUMN IF EXISTS embedding,
-- DROP COLUMN IF EXISTS embedding_model,
-- DROP COLUMN IF EXISTS embedding_language,
-- DROP COLUMN IF EXISTS was_translated,
-- DROP COLUMN IF EXISTS embedding_generated_at;
-- =====================================================