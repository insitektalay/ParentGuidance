-- ===============================================
-- DATABASE RESET SCRIPT FOR PARENTGUIDANCE APP
-- ===============================================
-- This script will completely reset the database to trigger fresh onboarding
-- Run these statements in your Supabase SQL Editor

-- ===============================================
-- STEP 1: CLEAR ALL USER DATA TABLES (in correct order)
-- ===============================================
-- Delete in order to respect foreign key constraints

-- Delete guidance records first (references situations)
DO $$
BEGIN
    DELETE FROM guidance;
    RAISE NOTICE 'Deleted from guidance table';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Could not delete from guidance: %', SQLERRM;
END $$;

-- Delete situations (references children and families)
DO $$
BEGIN
    DELETE FROM situations;
    RAISE NOTICE 'Deleted from situations table';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Could not delete from situations: %', SQLERRM;
END $$;

-- Delete family foundation tools (references children, families, foundation_tools)
DO $$
BEGIN
    DELETE FROM family_foundation_tools;
    RAISE NOTICE 'Deleted from family_foundation_tools table';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Could not delete from family_foundation_tools: %', SQLERRM;
END $$;

-- Delete children records (references families)
DO $$
BEGIN
    DELETE FROM children;
    RAISE NOTICE 'Deleted from children table';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Could not delete from children: %', SQLERRM;
END $$;

-- Delete framework recommendations (references families)
DO $$
BEGIN
    DELETE FROM framework_recommendations;
    RAISE NOTICE 'Deleted from framework_recommendations table';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Could not delete from framework_recommendations: %', SQLERRM;
END $$;

-- Delete profiles (references families and auth.users)
DO $$
BEGIN
    DELETE FROM profiles;
    RAISE NOTICE 'Deleted from profiles table';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Could not delete from profiles: %', SQLERRM;
END $$;

-- Delete foundation tools (standalone table)
DO $$
BEGIN
    DELETE FROM foundation_tools;
    RAISE NOTICE 'Deleted from foundation_tools table';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Could not delete from foundation_tools: %', SQLERRM;
END $$;

-- Delete families (parent table)
DO $$
BEGIN
    DELETE FROM families;
    RAISE NOTICE 'Deleted from families table';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Could not delete from families: %', SQLERRM;
END $$;

-- ===============================================
-- STEP 2: CLEAR AUTHENTICATION DATA
-- ===============================================

-- Delete all user sessions
DELETE FROM auth.sessions;

-- Delete all user identities
DELETE FROM auth.identities;

-- Delete all users from auth.users
DELETE FROM auth.users;

-- ===============================================
-- STEP 3: RESET SEQUENCES (if any exist)
-- ===============================================

-- Reset any sequences that might exist
-- Note: Supabase typically uses UUIDs, but just in case there are sequences

-- Check if sequences exist and reset them
DO $$
BEGIN
    -- Reset sequence for any auto-incrementing fields
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'children_id_seq') THEN
        ALTER SEQUENCE children_id_seq RESTART WITH 1;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'families_id_seq') THEN
        ALTER SEQUENCE families_id_seq RESTART WITH 1;
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'user_profiles_id_seq') THEN
        ALTER SEQUENCE user_profiles_id_seq RESTART WITH 1;
    END IF;
END $$;

-- ===============================================
-- STEP 4: VERIFICATION QUERIES
-- ===============================================

-- Run these queries to verify the database is empty:

-- Check children table
SELECT COUNT(*) as children_count FROM children;

-- Check profiles table (corrected from user_profiles)
SELECT COUNT(*) as profiles_count FROM profiles;

-- Check families table
SELECT COUNT(*) as families_count FROM families;

-- Check auth.users table
SELECT COUNT(*) as auth_users_count FROM auth.users;

-- Check situations table
SELECT COUNT(*) as situations_count FROM situations;

-- Check guidance table
SELECT COUNT(*) as guidance_count FROM guidance;

-- Check framework_recommendations table
SELECT COUNT(*) as framework_recommendations_count FROM framework_recommendations;

-- All counts should be 0 after running the reset

-- ===============================================
-- ALTERNATIVE: SAFER RESET (if you want to keep some data)
-- ===============================================

-- If you want to keep other users but only reset for your specific user:
-- Replace 'your-user-id-here' with your actual user ID

/*
-- Delete only your specific user's data
DELETE FROM children WHERE family_id IN (
    SELECT family_id FROM profiles WHERE id = 'your-user-id-here'
);

DELETE FROM profiles WHERE id = 'your-user-id-here';

DELETE FROM families WHERE id IN (
    SELECT family_id FROM profiles WHERE id = 'your-user-id-here'
);

DELETE FROM auth.users WHERE id = 'your-user-id-here';
*/

-- ===============================================
-- STEP 5: FINAL VERIFICATION
-- ===============================================

-- Run this comprehensive check to ensure everything is clean:
SELECT 
    'children' as table_name, COUNT(*) as record_count FROM children
UNION ALL
SELECT 
    'profiles' as table_name, COUNT(*) as record_count FROM profiles
UNION ALL
SELECT 
    'families' as table_name, COUNT(*) as record_count FROM families
UNION ALL
SELECT 
    'auth.users' as table_name, COUNT(*) as record_count FROM auth.users
UNION ALL
SELECT 
    'situations' as table_name, COUNT(*) as record_count FROM situations
UNION ALL
SELECT 
    'guidance' as table_name, COUNT(*) as record_count FROM guidance
UNION ALL
SELECT 
    'framework_recommendations' as table_name, COUNT(*) as record_count FROM framework_recommendations
ORDER BY table_name;

-- ===============================================
-- NOTES:
-- ===============================================
-- 1. After running this script, your app should start fresh
-- 2. You'll need to go through complete onboarding again
-- 3. This will test if onboarding properly creates child records
-- 4. Make sure to backup any important data before running this
-- 5. Run the verification queries to confirm the reset worked
-- 6. The app should now show the welcome/onboarding screen when launched

-- ===============================================
-- EXPECTED BEHAVIOR AFTER RESET:
-- ===============================================
-- 1. App launches and shows welcome screen
-- 2. You go through authentication
-- 3. You go through plan selection
-- 4. You go through child details entry
-- 5. Child should be created in database during onboarding
-- 6. Header should show actual child name instead of "Alex"