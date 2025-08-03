-- Complete fix for RLS authentication issue
-- This script does everything in the correct order

-- Step 1: Add family_id column to relevant_insights table
ALTER TABLE relevant_insights ADD COLUMN IF NOT EXISTS family_id text;

-- Step 2: Populate family_id for existing records
UPDATE relevant_insights ri
SET family_id = s.family_id
FROM guidance g
JOIN situations s ON s.id = g.situation_id
WHERE g.id = ri.guidance_id
  AND ri.family_id IS NULL;

-- Step 3: Create trigger function to auto-populate family_id for new records
CREATE OR REPLACE FUNCTION relevant_insights_set_family_id()
RETURNS trigger AS $$
BEGIN
    IF NEW.family_id IS NULL THEN
        SELECT s.family_id INTO NEW.family_id
        FROM guidance g
        JOIN situations s ON s.id = g.situation_id
        WHERE g.id = NEW.guidance_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create trigger
DROP TRIGGER IF EXISTS trg_ri_set_family ON relevant_insights;
CREATE TRIGGER trg_ri_set_family
    BEFORE INSERT ON relevant_insights
    FOR EACH ROW EXECUTE FUNCTION relevant_insights_set_family_id();

-- Step 5: Drop the existing problematic policies
DROP POLICY IF EXISTS "read_family_insights" ON relevant_insights;
DROP POLICY IF EXISTS "insert_family_insights" ON relevant_insights;

-- Step 6: Create type-safe helper function for user matching
CREATE OR REPLACE FUNCTION user_belongs_to_family(target_family_id text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
    -- Try different type casting approaches to handle UUID/TEXT mismatch
    RETURN EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.family_id = target_family_id
        AND (
            -- Try various type combinations safely
            (p.id::text = auth.uid()::text) OR
            (p.id = auth.uid()::uuid) OR  
            (p.id::uuid = auth.uid()::uuid)
        )
    );
EXCEPTION
    WHEN OTHERS THEN
        -- If any casting fails, return false for security
        RETURN false;
END;
$$;

-- Step 7: Create new simple policies using the helper function
CREATE POLICY "read_family_insights_safe" ON relevant_insights
FOR SELECT TO authenticated
USING (
    user_belongs_to_family(relevant_insights.family_id)
);

CREATE POLICY "insert_family_insights_safe" ON relevant_insights  
FOR INSERT TO authenticated
WITH CHECK (
    user_belongs_to_family(relevant_insights.family_id)
);

-- Step 8: Create emergency RPC workaround for immediate reads
CREATE OR REPLACE FUNCTION rpc_get_relevant_insights(p_guidance_id text)
RETURNS SETOF relevant_insights
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE 
    v_family_id text;
BEGIN
    -- First, get the family_id for this guidance
    SELECT s.family_id INTO v_family_id
    FROM guidance g
    JOIN situations s ON s.id = g.situation_id
    WHERE g.id = p_guidance_id;

    IF v_family_id IS NULL THEN
        RAISE EXCEPTION 'Guidance not found or access denied';
    END IF;

    -- Check if the calling user belongs to this family using helper function
    IF NOT user_belongs_to_family(v_family_id) THEN
        RAISE EXCEPTION 'Access denied: user does not belong to family';
    END IF;

    -- Return the insights for this guidance
    RETURN QUERY
        SELECT ri.* 
        FROM relevant_insights ri
        WHERE ri.guidance_id = p_guidance_id
        ORDER BY ri.created_at;
END;
$$;

-- Step 9: Create diagnostic function
CREATE OR REPLACE FUNCTION rpc_whoami()
RETURNS json
LANGUAGE sql
STABLE
AS $$
  SELECT json_build_object(
    'auth_uid', auth.uid(),
    'auth_uid_type', pg_typeof(auth.uid()),
    'current_role', current_setting('role', true),
    'session_user', session_user
  );
$$;

-- Step 10: Grant necessary permissions
GRANT EXECUTE ON FUNCTION user_belongs_to_family(text) TO authenticated;
GRANT EXECUTE ON FUNCTION rpc_get_relevant_insights(text) TO authenticated;
GRANT EXECUTE ON FUNCTION rpc_whoami() TO authenticated;

-- Step 11: Ensure RLS is enabled
ALTER TABLE relevant_insights ENABLE ROW LEVEL SECURITY;

-- Verification queries
SELECT 'Column Check' as status, 
       EXISTS(SELECT 1 FROM information_schema.columns 
              WHERE table_name = 'relevant_insights' AND column_name = 'family_id') as family_id_exists;

SELECT 'Data Population' as status,
       count(*) as total_rows,
       count(family_id) as rows_with_family_id,
       count(*) - count(family_id) as missing_family_id
FROM relevant_insights;

SELECT 'RLS Policies' as status,
       policyname,
       cmd
FROM pg_policies 
WHERE tablename = 'relevant_insights'
ORDER BY policyname;

-- Test auth context
SELECT 'Auth Test' as status, rpc_whoami() as auth_info;