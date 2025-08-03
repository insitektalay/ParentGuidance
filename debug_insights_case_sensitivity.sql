-- Check if the guidance IDs match case-sensitively
-- The issue might be that UUIDs are being compared with different casing

-- First, let's see all guidance records for the recent situation
SELECT 
    g.id as guidance_id,
    g.situation_id,
    g.created_at,
    s.id as situation_id_from_situations_table,
    s.created_at as situation_created_at
FROM guidance g
JOIN situations s ON LOWER(g.situation_id) = LOWER(s.id)
WHERE g.created_at > NOW() - INTERVAL '1 hour'
ORDER BY g.created_at DESC
LIMIT 5;

-- Now check if relevant insights exist for these guidances
SELECT 
    ri.guidance_id,
    COUNT(*) as insight_count,
    g.situation_id
FROM relevant_insights ri
JOIN guidance g ON ri.guidance_id = g.id
WHERE g.created_at > NOW() - INTERVAL '1 hour'
GROUP BY ri.guidance_id, g.situation_id;

-- Check if there's a case mismatch issue
SELECT 
    'Guidance Table' as source,
    id,
    UPPER(id) as upper_id,
    LOWER(id) as lower_id,
    situation_id
FROM guidance 
WHERE created_at > NOW() - INTERVAL '1 hour'
UNION ALL
SELECT 
    'Relevant Insights Table' as source,
    guidance_id as id,
    UPPER(guidance_id) as upper_id,
    LOWER(guidance_id) as lower_id,
    situation_id
FROM relevant_insights
WHERE created_at > NOW() - INTERVAL '1 hour';