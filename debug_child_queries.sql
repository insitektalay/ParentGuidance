-- SQL Queries to Debug Child Names in Database
-- Run these in your Supabase SQL editor or database client

-- 1. Show all children with their basic info
SELECT 
    id,
    name,
    age,
    family_id,
    created_at,
    updated_at
FROM children
ORDER BY created_at DESC;

-- 2. Show all families and their associated children
SELECT 
    f.id as family_id,
    f.created_at as family_created,
    c.id as child_id,
    c.name as child_name,
    c.age as child_age,
    c.created_at as child_created
FROM families f
LEFT JOIN children c ON f.id = c.family_id
ORDER BY f.created_at DESC, c.created_at DESC;

-- 3. Show user profiles with their family associations
SELECT 
    up.id as user_id,
    up.email,
    up.full_name,
    up.family_id,
    f.id as family_table_id,
    c.name as child_name,
    c.age as child_age
FROM user_profiles up
LEFT JOIN families f ON up.family_id = f.id
LEFT JOIN children c ON f.id = c.family_id
ORDER BY up.created_at DESC;

-- 4. Check for the specific family ID mentioned in the code
SELECT 
    f.id as family_id,
    c.id as child_id,
    c.name as child_name,
    c.age as child_age,
    c.family_id as child_family_id,
    c.created_at as child_created
FROM families f
LEFT JOIN children c ON f.id = c.family_id
WHERE f.id = '562fb7a3-3ba8-4f1b-92a8-ba6e468863e5'::uuid;

-- 5. Show data types and structure of children table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'children'
ORDER BY ordinal_position;

-- 6. Show data types and structure of families table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'families'
ORDER BY ordinal_position;

-- 7. Check if there are any children at all
SELECT COUNT(*) as total_children FROM children;

-- 8. Check if there are any families at all
SELECT COUNT(*) as total_families FROM families;

-- 9. Show any children with NULL or empty names
SELECT 
    id,
    name,
    family_id,
    CASE 
        WHEN name IS NULL THEN 'NULL'
        WHEN name = '' THEN 'EMPTY STRING'
        ELSE 'HAS VALUE'
    END as name_status
FROM children
WHERE name IS NULL OR name = '';

-- 10. Search for any child with "Betty" in the name
SELECT 
    id,
    name,
    age,
    family_id,
    created_at
FROM children
WHERE name ILIKE '%betty%'
ORDER BY created_at DESC;

-- 11. Search for any child with "Alex" in the name
SELECT 
    id,
    name,
    age,
    family_id,
    created_at
FROM children
WHERE name ILIKE '%alex%'
ORDER BY created_at DESC;

-- 12. Show all user profiles to find the current user
SELECT 
    id,
    email,
    full_name,
    family_id,
    selected_plan,
    plan_setup_complete,
    child_details_complete,
    created_at
FROM user_profiles
ORDER BY created_at DESC;

-- 13. Check foreign key constraints
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'children' AND tc.constraint_type = 'FOREIGN KEY';

-- 14. Raw count by family_id to see distribution
SELECT 
    family_id,
    COUNT(*) as child_count,
    STRING_AGG(name, ', ') as child_names
FROM children
GROUP BY family_id
ORDER BY child_count DESC;

-- 15. Check if the UUID format is causing issues
SELECT 
    id,
    name,
    family_id,
    family_id::text as family_id_as_text,
    LENGTH(family_id::text) as uuid_length
FROM children
LIMIT 5;