-- Fix ONLY the RLS policies to resolve UUID/TEXT type mismatch
-- This script focuses on just replacing the problematic policies

-- Step 1: Drop the existing problematic policies
drop policy if exists "read_family_insights" on relevant_insights;
drop policy if exists "insert_family_insights" on relevant_insights;

-- Step 2: Create type-safe helper function for user matching
create or replace function user_belongs_to_family(target_family_id text)
returns boolean
language plpgsql
stable
security definer
as $$
begin
    -- Try different type casting approaches to handle UUID/TEXT mismatch
    return exists (
        select 1 from profiles p
        where p.family_id = target_family_id
        and (
            -- Try various type combinations
            (p.id::text = auth.uid()::text) or
            (p.id = auth.uid()::uuid) or  
            (p.id::uuid = auth.uid()::uuid)
        )
    );
exception
    when others then
        -- If any casting fails, return false for security
        return false;
end;
$$;

-- Step 3: Create new simple policies using the helper function
create policy "read_family_insights_safe" on relevant_insights
for select to authenticated
using (
    user_belongs_to_family(relevant_insights.family_id)
);

create policy "insert_family_insights_safe" on relevant_insights  
for insert to authenticated
with check (
    user_belongs_to_family(relevant_insights.family_id)
);

-- Step 4: Grant necessary permissions
grant execute on function user_belongs_to_family(text) to authenticated;

-- Step 5: Verification
select 
    'Updated Policies' as status,
    policyname,
    cmd
from pg_policies 
where tablename = 'relevant_insights'
order by policyname;

-- Step 6: Test the helper function (replace 'test-family-id' with a real one)
-- select user_belongs_to_family('test-family-id') as test_result;