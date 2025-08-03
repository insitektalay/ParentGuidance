-- Diagnostic script to check data types before fixing RLS policies

-- Check the data type of profiles.id column
SELECT 
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns 
WHERE table_name = 'profiles' 
  AND column_name = 'id';

-- Check the data type of relevant_insights.family_id column  
SELECT 
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns 
WHERE table_name = 'relevant_insights' 
  AND column_name = 'family_id';

-- Check what auth.uid() returns
SELECT 
    auth.uid() as auth_uid_value,
    pg_typeof(auth.uid()) as auth_uid_type;

-- Check sample data types from actual tables
SELECT 
    'profiles.id type:' as info,
    pg_typeof(id) as actual_type
FROM profiles 
LIMIT 1;

-- Show any existing policies on relevant_insights for reference
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'relevant_insights';