-- Time Machine Migration Script
-- Run this script to set up all time machine tables and procedures

\echo 'Starting Time Machine migrations...'

-- Migration 1: Create regen_runs table
\echo 'Creating regen_runs table...'
\i migrations/time_machine/001_create_regen_runs_table.sql

-- Migration 2: Add regen_run_id columns
\echo 'Adding regen_run_id columns...'
\i migrations/time_machine/002_add_regen_run_id_columns.sql

-- Migration 3: Create gold/redline response tables
\echo 'Creating gold and redline response tables...'
\i migrations/time_machine/003_create_gold_responses_table.sql

-- Migration 4: Create experiment tables
\echo 'Creating experiment tables...'
\i migrations/time_machine/004_create_experiment_tables.sql

-- Migration 5: Create reset procedure
\echo 'Creating reset procedure...'
\i migrations/time_machine/005_create_reset_archive_procedure.sql

\echo 'Time Machine migrations completed successfully!'

-- Display summary
SELECT 'Time Machine Setup Complete' as status,
       (SELECT COUNT(*) FROM regen_runs) as regen_runs_count,
       (SELECT COUNT(*) FROM experiment_runs) as experiment_runs_count,
       (SELECT COUNT(*) FROM gold_responses) as gold_responses_count,
       (SELECT COUNT(*) FROM redline_responses) as redline_responses_count;