-- ===============================================
-- CREATE USER_API_KEYS TABLE FOR MULTI-PROVIDER SUPPORT
-- ===============================================
-- This script creates the user_api_keys table to support multiple AI providers
-- Run this SQL in your Supabase SQL Editor BEFORE deploying the app changes

-- ===============================================
-- STEP 1: CREATE USER_API_KEYS TABLE
-- ===============================================

CREATE TABLE user_api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    provider TEXT NOT NULL CHECK (provider IN ('openai', 'anthropic', 'xai', 'google')),
    api_key TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    
    -- Ensure only one active provider per user
    CONSTRAINT unique_active_provider_per_user UNIQUE (user_id, is_active) DEFERRABLE INITIALLY DEFERRED,
    
    -- Ensure unique provider per user (user can only have one key per provider)
    CONSTRAINT unique_provider_per_user UNIQUE (user_id, provider)
);

-- ===============================================
-- STEP 2: CREATE INDEXES FOR PERFORMANCE
-- ===============================================

-- Index for finding user's active API key (most common query)
CREATE INDEX idx_user_api_keys_user_active ON user_api_keys(user_id, is_active) WHERE is_active = true;

-- Index for finding all keys for a user
CREATE INDEX idx_user_api_keys_user_id ON user_api_keys(user_id);

-- Index for provider lookups
CREATE INDEX idx_user_api_keys_provider ON user_api_keys(provider);

-- ===============================================
-- STEP 3: CREATE ROW LEVEL SECURITY POLICIES
-- ===============================================

-- Enable RLS on the table
ALTER TABLE user_api_keys ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own API keys
CREATE POLICY "Users can view their own API keys" ON user_api_keys
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can only insert their own API keys
CREATE POLICY "Users can insert their own API keys" ON user_api_keys
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update their own API keys
CREATE POLICY "Users can update their own API keys" ON user_api_keys
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can only delete their own API keys
CREATE POLICY "Users can delete their own API keys" ON user_api_keys
    FOR DELETE USING (auth.uid() = user_id);

-- ===============================================
-- STEP 4: CREATE TRIGGER FOR UPDATED_AT
-- ===============================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_user_api_keys_updated_at
    BEFORE UPDATE ON user_api_keys
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- STEP 5: CREATE FUNCTION TO ENSURE ONLY ONE ACTIVE KEY
-- ===============================================

-- Function to ensure only one API key is active per user
CREATE OR REPLACE FUNCTION ensure_single_active_api_key()
RETURNS TRIGGER AS $$
BEGIN
    -- If we're setting a key to active, deactivate all others for this user
    IF NEW.is_active = true THEN
        UPDATE user_api_keys 
        SET is_active = false, updated_at = timezone('utc'::text, now())
        WHERE user_id = NEW.user_id 
        AND id != NEW.id 
        AND is_active = true;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to ensure only one active key per user
CREATE TRIGGER ensure_single_active_api_key_trigger
    AFTER INSERT OR UPDATE ON user_api_keys
    FOR EACH ROW
    WHEN (NEW.is_active = true)
    EXECUTE FUNCTION ensure_single_active_api_key();

-- ===============================================
-- STEP 6: MIGRATION FROM EXISTING user_api_key FIELD
-- ===============================================

-- Migrate existing API keys from profiles table to user_api_keys table
-- This preserves existing user data during the transition
INSERT INTO user_api_keys (user_id, provider, api_key, is_active, created_at, updated_at)
SELECT 
    id as user_id,
    COALESCE(api_key_provider, 'openai') as provider,
    user_api_key as api_key,
    true as is_active,
    created_at,
    updated_at
FROM profiles 
WHERE user_api_key IS NOT NULL 
AND user_api_key != ''
ON CONFLICT (user_id, provider) DO NOTHING;

-- ===============================================
-- STEP 7: VERIFICATION QUERIES
-- ===============================================

-- Check if the table was created successfully
SELECT 
    'user_api_keys table' as check_name,
    COUNT(*) as record_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT provider) as unique_providers
FROM user_api_keys;

-- Check migrated data
SELECT 
    provider,
    COUNT(*) as key_count,
    COUNT(CASE WHEN is_active THEN 1 END) as active_count
FROM user_api_keys
GROUP BY provider
ORDER BY provider;

-- Check for users with active keys
SELECT 
    u.user_id,
    u.provider,
    u.is_active,
    p.email
FROM user_api_keys u
JOIN profiles p ON u.user_id = p.id
WHERE u.is_active = true
ORDER BY p.email;

-- ===============================================
-- STEP 8: CLEANUP (OPTIONAL - RUN AFTER APP DEPLOYMENT)
-- ===============================================

-- IMPORTANT: Only run these after confirming the new system works
-- These remove the old single API key fields from profiles table

/*
-- Remove old API key columns from profiles table
-- ALTER TABLE profiles DROP COLUMN user_api_key;
-- ALTER TABLE profiles DROP COLUMN api_key_provider;
*/

-- ===============================================
-- EXPECTED RESULTS
-- ===============================================

-- After running this migration:
-- 1. New user_api_keys table with proper constraints and security
-- 2. All existing API keys migrated to the new table
-- 3. Users can have multiple provider keys but only one active at a time
-- 4. RLS policies ensure users can only access their own keys
-- 5. Automatic triggers maintain data integrity

-- ===============================================
-- ROLLBACK PLAN (if needed)
-- ===============================================

/*
-- To rollback this migration:
DROP TRIGGER IF EXISTS ensure_single_active_api_key_trigger ON user_api_keys;
DROP TRIGGER IF EXISTS update_user_api_keys_updated_at ON user_api_keys;
DROP FUNCTION IF EXISTS ensure_single_active_api_key();
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP TABLE IF EXISTS user_api_keys;
*/