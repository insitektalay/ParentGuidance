-- Fix Relevant Insights RLS Authentication Issue - CORRECTED VERSION
-- This version fixes UUID/TEXT type casting issues

-- Phase 1: Diagnostic RPC function

-- Create diagnostic function to test auth context
create or replace function rpc_whoami()
returns json
language sql
stable
as $$
  select json_build_object(
    'auth_uid', auth.uid(),
    'current_role', current_setting('role', true),
    'session_user', session_user,
    'jwt_claims', current_setting('request.jwt.claims', true)
  );
$$;

-- Grant execute permission to authenticated users
revoke all on function rpc_whoami() from public;
grant execute on function rpc_whoami() to authenticated;

-- Phase 2: Add family_id denormalization

-- Add family_id column to relevant_insights table
alter table relevant_insights add column if not exists family_id text;

-- Create trigger function to auto-populate family_id
create or replace function relevant_insights_set_family_id()
returns trigger as $$
begin
  if new.family_id is null then
    select s.family_id into new.family_id
    from guidance g
    join situations s on s.id = g.situation_id
    where g.id = new.guidance_id;
  end if;
  return new;
end;
$$ language plpgsql;

-- Create trigger
drop trigger if exists trg_ri_set_family on relevant_insights;
create trigger trg_ri_set_family
before insert on relevant_insights
for each row execute function relevant_insights_set_family_id();

-- Phase 3: Create simplified RLS policies using family_id

-- Ensure RLS is enabled
alter table relevant_insights enable row level security;

-- Drop all existing policies first
drop policy if exists "read_family_insights" on relevant_insights;
drop policy if exists "insert_family_insights" on relevant_insights;
drop policy if exists "read_family_insights_simple" on relevant_insights;
drop policy if exists "insert_family_insights_simple" on relevant_insights;
drop policy if exists "Users can create relevant insights for their situations" on relevant_insights;
drop policy if exists "Users can delete relevant insights for their family situations" on relevant_insights;
drop policy if exists "Users can insert relevant insights for their family situations" on relevant_insights;
drop policy if exists "Users can read relevant insights for their family situations" on relevant_insights;
drop policy if exists "Users can read their own family's relevant insights" on relevant_insights;
drop policy if exists "Users can update relevant insights for their family situations" on relevant_insights;

-- Create simple, efficient policies using family_id with proper type casting
create policy "read_family_insights_simple" on relevant_insights
for select to authenticated
using (
  exists (
    select 1 from profiles p
    where p.id::text = auth.uid()::text
      and p.family_id = relevant_insights.family_id
  )
);

create policy "insert_family_insights_simple" on relevant_insights
for insert to authenticated
with check (
  exists (
    select 1 from profiles p
    where p.id::text = auth.uid()::text
      and p.family_id = coalesce(new.family_id, relevant_insights.family_id)
  )
);

-- Phase 4: Backfill existing relevant_insights with family_id

-- Update existing records that don't have family_id set
update relevant_insights ri
set family_id = s.family_id
from guidance g
join situations s on s.id = g.situation_id
where g.id = ri.guidance_id
  and ri.family_id is null;

-- Phase 5: Emergency RPC workaround for immediate reads

-- Create security definer function that bypasses table RLS
create or replace function rpc_get_relevant_insights(p_guidance_id text)
returns setof relevant_insights
language plpgsql
security definer
as $$
declare 
    v_family_id text;
begin
    -- First, authorize: ensure caller belongs to the family for this guidance
    select s.family_id into v_family_id
    from guidance g
    join situations s on s.id = g.situation_id
    where g.id = p_guidance_id;

    if v_family_id is null then
        raise exception 'Guidance not found or access denied';
    end if;

    -- Check if the calling user belongs to this family (with proper type casting)
    if not exists (
        select 1 from profiles p
        where p.id::text = auth.uid()::text
          and p.family_id = v_family_id
    ) then
        raise exception 'Access denied: user does not belong to family';
    end if;

    -- Return the insights for this guidance
    return query
        select ri.* 
        from relevant_insights ri
        where ri.guidance_id = p_guidance_id
        order by ri.created_at;
end;
$$;

-- Grant execute permission to authenticated users only
revoke all on function rpc_get_relevant_insights(text) from public;
grant execute on function rpc_get_relevant_insights(text) to authenticated;

-- Verification queries

-- Check RLS policies
select 
    'RLS Policies Status' as status,
    policyname,
    cmd
from pg_policies 
where tablename = 'relevant_insights'
order by policyname;

-- Check backfill status
select 
    'Backfill Status' as status,
    count(*) as total_rows,
    count(family_id) as rows_with_family_id,
    count(*) - count(family_id) as missing_family_id
from relevant_insights;

-- Test auth context (run this after executing to verify)
-- select rpc_whoami();

-- Test RPC function (replace with real guidance_id)
-- select * from rpc_get_relevant_insights('your-guidance-id-here');