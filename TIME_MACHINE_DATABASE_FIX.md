# Time Machine Database Schema Fix

## Problem
Time Machine regeneration fails with: `column "situation_id" does not exist`

## Quick Diagnosis
1. Open **Supabase SQL Editor**
2. Run `diagnose_time_machine_schema.sql` to see what's missing

## Fix Options

### Option 1: Quick Fix (Recommended for immediate testing)
**Run this in Supabase SQL Editor:**
```sql
\i quick_fix_reset_function.sql
```

**What it does:**
- Creates a flexible version of `reset_family_derived_data` that adapts to your current schema
- Works with both `situation_id` and `situationId` column names
- Handles missing tables gracefully
- **Should fix your immediate Time Machine issue**

### Option 2: Schema Repair (If you have existing data)
**Run this in Supabase SQL Editor:**
```sql
\i fix_time_machine_schema.sql
```

**What it does:**
- Renames camelCase columns to snake_case (`situationId` → `situation_id`)
- Fixes UUID/TEXT type mismatches
- Repairs most common schema issues

### Option 3: Full Migration (Clean setup)
**Run this in Supabase SQL Editor:**
```sql
\i run_time_machine_migrations.sql
```

**What it does:**
- Creates all Time Machine tables from scratch
- Sets up proper relationships and constraints
- **Warning:** Only use if you don't have important Time Machine data

## Testing After Fix
1. Try your Time Machine regeneration again (Aug 4-5 test)
2. You should now see complete logs like:
   ```
   [11:37:47] Resetting derived data for family...
   [11:37:47]   → Calling reset_family_derived_data function...
   [11:37:48]   ✓ Database reset completed successfully
   [11:37:48] Reset complete: {"guidance_deleted": 3, ...}
   [11:37:48] Fetched 5 total situations for family
   [11:37:48] Applying date filter: 2025-08-04T00:00:00Z to 2025-08-06T00:00:00Z
   [11:37:48] Filtered to 1 situations in date range
   [11:37:48] Starting regeneration for 1 situations
   ```

## What to Expect
After running **Option 1** (quick fix), your Time Machine should work immediately and you'll see the full regeneration process with detailed logging.

## If Issues Persist
- Check the SQL execution results for any error messages
- Run the diagnostic script again to verify the fix
- The flexible function provides detailed logging about what it finds and does