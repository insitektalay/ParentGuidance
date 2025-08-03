-- Add family_id column and populate it (run this first if column doesn't exist)

-- Add family_id column to relevant_insights table
ALTER TABLE relevant_insights ADD COLUMN IF NOT EXISTS family_id text;

-- Populate family_id for existing records
UPDATE relevant_insights ri
SET family_id = s.family_id
FROM guidance g
JOIN situations s ON s.id = g.situation_id
WHERE g.id = ri.guidance_id
  AND ri.family_id IS NULL;

-- Create trigger function to auto-populate family_id for new records
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

-- Create trigger
DROP TRIGGER IF EXISTS trg_ri_set_family ON relevant_insights;
CREATE TRIGGER trg_ri_set_family
    BEFORE INSERT ON relevant_insights
    FOR EACH ROW EXECUTE FUNCTION relevant_insights_set_family_id();

-- Verify the column was added and populated
SELECT 
    'family_id column status' as status,
    count(*) as total_rows,
    count(family_id) as rows_with_family_id
FROM relevant_insights;