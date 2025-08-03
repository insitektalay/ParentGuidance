-- Simple fix for UUID/TEXT casting error in existing RLS policies

-- Step 1: Drop the problematic policies
DROP POLICY IF EXISTS "read_family_insights" ON relevant_insights;
DROP POLICY IF EXISTS "insert_family_insights" ON relevant_insights;

-- Step 2: Recreate with proper type casting
CREATE POLICY "read_family_insights" ON relevant_insights
FOR SELECT USING (
    EXISTS (
        SELECT 1
        FROM guidance g
        JOIN situations s ON s.id = g.situation_id
        JOIN profiles p ON p.family_id = s.family_id
        WHERE g.id = relevant_insights.guidance_id
        AND p.id::text = auth.uid()::text
    )
);

CREATE POLICY "insert_family_insights" ON relevant_insights
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1
        FROM guidance g
        JOIN situations s ON s.id = g.situation_id  
        JOIN profiles p ON p.family_id = s.family_id
        WHERE g.id = relevant_insights.guidance_id
        AND p.id::text = auth.uid()::text
    )
);

-- Step 3: Add emergency RPC workaround
CREATE OR REPLACE FUNCTION rpc_get_relevant_insights(p_guidance_id text)
RETURNS SETOF relevant_insights
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE 
    v_family_id text;
BEGIN
    -- Get the family_id for this guidance
    SELECT s.family_id INTO v_family_id
    FROM guidance g
    JOIN situations s ON s.id = g.situation_id
    WHERE g.id = p_guidance_id;

    IF v_family_id IS NULL THEN
        RAISE EXCEPTION 'Guidance not found';
    END IF;

    -- Check if user belongs to this family
    IF NOT EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.id::text = auth.uid()::text
          AND p.family_id = v_family_id
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    -- Return the insights
    RETURN QUERY
        SELECT ri.* 
        FROM relevant_insights ri
        WHERE ri.guidance_id = p_guidance_id
        ORDER BY ri.created_at;
END;
$$;

-- Step 4: Grant permissions
GRANT EXECUTE ON FUNCTION rpc_get_relevant_insights(text) TO authenticated;

-- Verification
SELECT 
    'Fixed Policies' as status,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'relevant_insights'
ORDER BY policyname;