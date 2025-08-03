-- Phase 3: Complete Denormalized Solution - The Missing Piece
-- This implements the robust architectural fix that was never delivered

-- Step 1: Add family_id column with correct type
ALTER TABLE public.relevant_insights 
  ADD COLUMN IF NOT EXISTS family_id text;

-- Step 2: Backfill existing data using joins
UPDATE public.relevant_insights ri
SET family_id = s.family_id
FROM public.guidance g
JOIN public.situations s ON s.id = g.situation_id
WHERE g.id = ri.guidance_id
  AND ri.family_id IS NULL;

-- Step 3: Create trigger function to auto-populate family_id on insert
CREATE OR REPLACE FUNCTION public.relevant_insights_set_family_id()
RETURNS trigger 
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.family_id IS NULL THEN
    SELECT s.family_id INTO NEW.family_id
    FROM public.guidance g
    JOIN public.situations s ON s.id = g.situation_id
    WHERE g.id = NEW.guidance_id;
  END IF;
  RETURN NEW;
END;
$$;

-- Step 4: Create trigger
DROP TRIGGER IF EXISTS trg_ri_set_family ON public.relevant_insights;
CREATE TRIGGER trg_ri_set_family
  BEFORE INSERT ON public.relevant_insights
  FOR EACH ROW 
  EXECUTE FUNCTION public.relevant_insights_set_family_id();

-- Step 5: Replace complex RLS policies with simple family_id checks
ALTER TABLE public.relevant_insights ENABLE ROW LEVEL SECURITY;

-- Drop existing complex policies
DROP POLICY IF EXISTS read_family_insights ON public.relevant_insights;
DROP POLICY IF EXISTS insert_family_insights ON public.relevant_insights;

-- Create minimal, robust RLS policies (no cross-table joins)
CREATE POLICY read_family_insights_simple ON public.relevant_insights
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()           -- p.id is UUID
        AND p.family_id = family_id     -- family_id is TEXT
    )
  );

CREATE POLICY insert_family_insights_simple ON public.relevant_insights
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.family_id = NEW.family_id
    )
  );

-- Step 6: Add performance indexes
CREATE INDEX IF NOT EXISTS idx_ri_guidance ON public.relevant_insights(guidance_id);
CREATE INDEX IF NOT EXISTS idx_ri_family   ON public.relevant_insights(family_id);

-- Step 7: Verification queries
SELECT 
  'Migration Status' as check_type,
  COUNT(*) as total_rows,
  COUNT(family_id) as rows_with_family_id,
  COUNT(*) - COUNT(family_id) as missing_family_id
FROM public.relevant_insights;

-- Check new policies
SELECT 
  'New Policies' as status,
  policyname,
  cmd
FROM pg_policies 
WHERE tablename = 'relevant_insights'
  AND schemaname = 'public'
ORDER BY policyname;

-- Test family_id population
SELECT 
  'Family ID Sample' as check_type,
  family_id,
  COUNT(*) as insights_count
FROM public.relevant_insights 
WHERE family_id IS NOT NULL
GROUP BY family_id
LIMIT 5;