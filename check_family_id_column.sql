-- Check if family_id column exists and has data

-- Check if family_id column exists in relevant_insights table
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'relevant_insights' 
  AND column_name = 'family_id';

-- Check if any relevant_insights rows have family_id populated
SELECT 
    'family_id status' as check_type,
    count(*) as total_rows,
    count(family_id) as rows_with_family_id,
    count(*) - count(family_id) as missing_family_id
FROM relevant_insights;

-- Show sample family_id values (if any)
SELECT 
    'sample family_ids' as check_type,
    family_id,
    count(*) as count
FROM relevant_insights 
WHERE family_id IS NOT NULL
GROUP BY family_id
LIMIT 5;