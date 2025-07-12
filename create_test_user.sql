-- ===============================================
-- CREATE TEST USER FOR PARENTGUIDANCE APP
-- ===============================================
-- This script creates a test user account so you can sign in and complete onboarding
-- Run these statements in your Supabase SQL Editor

-- ===============================================
-- STEP 1: CREATE FAMILY RECORD FIRST
-- ===============================================

-- Create a family record first (required for profile)
INSERT INTO families (
    id,
    created_at,
    updated_at,
    cultural_background,
    parenting_philosophy,
    household_structure,
    family_values
) VALUES (
    '12345678-1234-5678-9012-123456789001',
    now(),
    now(),
    null,
    null,
    null,
    null
);

-- ===============================================
-- STEP 2: CREATE USER & PROFILE (SIMPLIFIED)
-- ===============================================

-- Create a test user in the auth.users table with minimal required fields
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    '12345678-1234-5678-9012-123456789002',
    'authenticated',
    'authenticated',
    'test@example.com',
    '$2a$10$abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz',
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"email":"test@example.com","email_verified":true}',
    now(),
    now(),
    '',
    '',
    '',
    ''
);

-- Create a profile record linked to the user and family
INSERT INTO profiles (
    id,
    family_id,
    email,
    full_name,
    role,
    created_at,
    updated_at,
    selected_plan,
    plan_setup_complete,
    child_details_complete,
    onboarding_completed_at,
    subscription_status,
    subscription_id,
    user_api_key,
    api_key_provider,
    active_framework_name,
    framework_recommendation
) VALUES (
    '12345678-1234-5678-9012-123456789002',
    '12345678-1234-5678-9012-123456789001',
    'test@example.com',
    'Test User',
    'parent',
    now(),
    now(),
    null,  -- No plan selected yet
    false, -- Plan setup not complete
    false, -- Child details not complete
    null,  -- Onboarding not completed
    null,
    null,
    null,
    null,
    null,
    null
);

-- ===============================================
-- VERIFICATION QUERIES
-- ===============================================

-- Check if the user was created successfully
SELECT 
    'auth.users' as table_name,
    email,
    id,
    created_at
FROM auth.users 
WHERE email = 'test@example.com';

-- Check if the profile was created successfully
SELECT 
    'profiles' as table_name,
    email,
    full_name,
    id,
    family_id,
    selected_plan,
    plan_setup_complete,
    child_details_complete
FROM profiles 
WHERE email = 'test@example.com';

-- Check if the family was created successfully
SELECT 
    'families' as table_name,
    id,
    created_at
FROM families 
WHERE id = '12345678-1234-5678-9012-123456789001';

-- ===============================================
-- ALTERNATIVE: SIMPLER USER CREATION
-- ===============================================
-- If the above doesn't work, try this simpler approach:

/*
-- Just create the profile (if auth allows it)
INSERT INTO profiles (
    id,
    email,
    full_name,
    role,
    created_at,
    updated_at,
    selected_plan,
    plan_setup_complete,
    child_details_complete
) VALUES (
    gen_random_uuid(),
    'test@example.com',
    'Test User',
    'parent',
    now(),
    now(),
    null,
    false,
    false
);
*/

-- ===============================================
-- INSTRUCTIONS FOR USE
-- ===============================================
-- After running this script:
-- 1. Launch your app
-- 2. Choose "Continue with Email" 
-- 3. Enter email: test@example.com
-- 4. Enter any password (the app should let you in)
-- 5. Go through the onboarding flow:
--    - Select a plan
--    - Enter child details
--    - Complete setup
-- 6. Check if the child name appears in the header

-- ===============================================
-- EXPECTED BEHAVIOR
-- ===============================================
-- 1. App should recognize the test user
-- 2. Since onboarding is incomplete, it should take you through the flow
-- 3. When you enter child details, it should create a child record
-- 4. After completion, the header should show the child's name

-- ===============================================
-- TROUBLESHOOTING
-- ===============================================
-- If sign-in still fails:
-- 1. Check that the user exists: SELECT * FROM auth.users WHERE email = 'test@example.com';
-- 2. Check that the profile exists: SELECT * FROM profiles WHERE email = 'test@example.com';
-- 3. Try creating a user through the Supabase dashboard instead
-- 4. Or use the Supabase Auth API to create the user properly

-- ===============================================
-- CLEANUP (if needed)
-- ===============================================
-- To remove the test user:
/*
DELETE FROM profiles WHERE email = 'test@example.com';
DELETE FROM families WHERE id = 'family-uuid-12345678-1234-5678-9012-123456789012';
DELETE FROM auth.users WHERE email = 'test@example.com';
*/