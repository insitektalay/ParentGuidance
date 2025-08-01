-- =====================================================
-- Create Settings Table for Embedding Configuration
-- =====================================================
-- This script creates a settings table to store configuration
-- values like the current embedding dimension, ensuring that
-- future model swaps won't silently break vector inserts.
--
-- Run this script in your Supabase SQL Editor
-- =====================================================

-- Create settings table
CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policy for settings table (family-level access)
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Create policy to allow authenticated users to read settings
CREATE POLICY "authenticated_users_can_read_settings" ON settings
    FOR SELECT USING (auth.role() = 'authenticated');

-- Only service role can modify settings (for admin purposes)
CREATE POLICY "service_role_can_modify_settings" ON settings
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Insert current embedding dimension setting
INSERT INTO settings (key, value, description) 
VALUES (
    'current_embedding_dimension', 
    '1536', 
    'Current embedding vector dimension for text-embedding-3-small model. Change this when switching embedding models to prevent dimension mismatches.'
)
ON CONFLICT (key) DO UPDATE SET
    updated_at = NOW(),
    description = EXCLUDED.description;

-- Insert deduplication threshold settings
INSERT INTO settings (key, value, description) 
VALUES (
    'similarity_threshold_regulation', 
    '0.90', 
    'Similarity threshold for regulation insights deduplication (0.0-1.0). Higher values mean stricter similarity matching.'
)
ON CONFLICT (key) DO UPDATE SET
    updated_at = NOW(),
    description = EXCLUDED.description;

INSERT INTO settings (key, value, description) 
VALUES (
    'similarity_threshold_contextual', 
    '0.85', 
    'Similarity threshold for contextual insights deduplication (0.0-1.0). Slightly lower than regulation to catch more duplicates.'
)
ON CONFLICT (key) DO UPDATE SET
    updated_at = NOW(),
    description = EXCLUDED.description;

-- Insert embedding model setting for future reference
INSERT INTO settings (key, value, description)
VALUES (
    'embedding_model', 
    'text-embedding-3-small', 
    'Current OpenAI embedding model being used. Update this when changing models.'
)
ON CONFLICT (key) DO UPDATE SET
    updated_at = NOW(),
    description = EXCLUDED.description;

-- Add updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW(); 
   RETURN NEW;
END;
$$ language 'plpgsql';

-- Add trigger to automatically update updated_at column
CREATE TRIGGER update_settings_updated_at 
    BEFORE UPDATE ON settings 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Add comment to the table
COMMENT ON TABLE settings IS 
'Configuration settings for the application, including embedding dimensions and deduplication thresholds. This table prevents issues when switching AI models by maintaining current configuration state.';

-- Verify the settings were created correctly
SELECT 
    key,
    value,
    description,
    created_at
FROM settings
ORDER BY key;

-- =====================================================
-- Helper Functions for Settings Access
-- =====================================================

-- Function to get current embedding dimension
CREATE OR REPLACE FUNCTION get_embedding_dimension()
RETURNS INTEGER AS $$
DECLARE
    dimension_value TEXT;
BEGIN
    SELECT value INTO dimension_value 
    FROM settings 
    WHERE key = 'current_embedding_dimension';
    
    IF dimension_value IS NULL THEN
        RAISE EXCEPTION 'Embedding dimension not found in settings table';
    END IF;
    
    RETURN dimension_value::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Function to get similarity threshold by type
CREATE OR REPLACE FUNCTION get_similarity_threshold(threshold_type TEXT)
RETURNS FLOAT AS $$
DECLARE
    threshold_value TEXT;
    setting_key TEXT;
BEGIN
    setting_key := 'similarity_threshold_' || threshold_type;
    
    SELECT value INTO threshold_value 
    FROM settings 
    WHERE key = setting_key;
    
    IF threshold_value IS NULL THEN
        RAISE EXCEPTION 'Similarity threshold not found for type: %', threshold_type;
    END IF;
    
    RETURN threshold_value::FLOAT;
END;
$$ LANGUAGE plpgsql;

-- Test the helper functions
SELECT 
    'current_embedding_dimension' as setting,
    get_embedding_dimension() as value;

SELECT 
    'regulation_similarity_threshold' as setting,
    get_similarity_threshold('regulation') as value;

SELECT 
    'contextual_similarity_threshold' as setting,
    get_similarity_threshold('contextual') as value;

-- =====================================================
-- USAGE EXAMPLES
-- =====================================================
--
-- To update embedding dimension when switching models:
-- UPDATE settings 
-- SET value = '3072', description = 'Updated to text-embedding-3-large model'
-- WHERE key = 'current_embedding_dimension';
--
-- To adjust similarity thresholds:
-- UPDATE settings 
-- SET value = '0.88'
-- WHERE key = 'similarity_threshold_regulation';
--
-- =====================================================