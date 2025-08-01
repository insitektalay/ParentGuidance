-- =====================================================
-- Backfill Embeddings for Existing Insights
-- =====================================================
-- This script backfills vector embeddings for existing insights
-- in both insight_bullet_points and contextual_insights tables.
--
-- IMPORTANT: This script is designed to work with the Edge Function
-- 'generate_embedding' operation. Make sure the Edge Function is
-- deployed before running this script.
--
-- Run this script in chunks to avoid overwhelming the API.
-- =====================================================

-- Step 1: Check current state of embeddings
SELECT 
    'insight_bullet_points' as table_name,
    COUNT(*) as total_records,
    COUNT(embedding) as records_with_embeddings,
    COUNT(*) - COUNT(embedding) as records_missing_embeddings
FROM insight_bullet_points

UNION ALL

SELECT 
    'contextual_insights' as table_name,
    COUNT(*) as total_records,
    COUNT(embedding) as records_with_embeddings,
    COUNT(*) - COUNT(embedding) as records_missing_embeddings
FROM contextual_insights;

-- Step 2: Show sample records that need embeddings
SELECT 
    'insight_bullet_points' as table_name,
    id,
    content,
    category,
    created_at
FROM insight_bullet_points
WHERE embedding IS NULL
ORDER BY created_at DESC
LIMIT 10;

SELECT 
    'contextual_insights' as table_name,
    id,
    content,
    category,
    created_at
FROM contextual_insights
WHERE embedding IS NULL
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- BACKFILL FUNCTION
-- =====================================================
-- This function will be used to process batches of insights
-- and generate embeddings using the Edge Function

CREATE OR REPLACE FUNCTION backfill_embeddings_batch(
    target_table text,
    batch_size integer DEFAULT 50,
    start_offset integer DEFAULT 0
)
RETURNS TABLE (
    processed_count integer,
    success_count integer,
    error_count integer,
    batch_time_ms integer
) AS $$
DECLARE
    record_cursor CURSOR FOR 
        SELECT id, content 
        FROM insight_bullet_points 
        WHERE embedding IS NULL 
        ORDER BY created_at ASC
        LIMIT batch_size OFFSET start_offset
        WHEN target_table = 'insight_bullet_points'
    UNION ALL
        SELECT id, content 
        FROM contextual_insights 
        WHERE embedding IS NULL 
        ORDER BY created_at ASC
        LIMIT batch_size OFFSET start_offset
        WHEN target_table = 'contextual_insights';
    
    insight_record RECORD;
    start_time timestamp;
    end_time timestamp;
    batch_processed integer := 0;
    batch_success integer := 0;
    batch_errors integer := 0;
    
BEGIN
    start_time := clock_timestamp();
    
    -- Note: This function provides structure but cannot directly call Edge Functions
    -- The actual backfill should be done from application code or a separate script
    -- that can make HTTP requests to the Edge Function
    
    RAISE NOTICE 'Backfill function called for table: %, batch_size: %, offset: %', 
                 target_table, batch_size, start_offset;
    
    -- This is a placeholder - actual implementation would need to be done
    -- through application code that can call the Edge Function
    RAISE NOTICE 'This function needs to be implemented in application code that can call Edge Functions';
    
    end_time := clock_timestamp();
    
    RETURN QUERY SELECT 
        batch_processed,
        batch_success, 
        batch_errors,
        EXTRACT(MILLISECONDS FROM (end_time - start_time))::integer;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- MONITORING QUERIES
-- =====================================================

-- Function to get backfill progress
CREATE OR REPLACE FUNCTION get_backfill_progress()
RETURNS TABLE (
    table_name text,
    total_records bigint,
    with_embeddings bigint,
    missing_embeddings bigint,
    completion_percentage numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'insight_bullet_points'::text,
        COUNT(*)::bigint,
        COUNT(embedding)::bigint,
        (COUNT(*) - COUNT(embedding))::bigint,
        ROUND((COUNT(embedding)::numeric / COUNT(*)) * 100, 2)
    FROM insight_bullet_points
    
    UNION ALL
    
    SELECT 
        'contextual_insights'::text,
        COUNT(*)::bigint,
        COUNT(embedding)::bigint,
        (COUNT(*) - COUNT(embedding))::bigint,
        ROUND((COUNT(embedding)::numeric / COUNT(*)) * 100, 2)
    FROM contextual_insights;
END;
$$ LANGUAGE plpgsql;

-- Check progress
SELECT * FROM get_backfill_progress();

-- =====================================================
-- APPLICATION CODE EXAMPLE (TypeScript/Deno)
-- =====================================================
/*

This is example code that would run the actual backfill process:

```typescript
// backfill-embeddings.ts - Run this with Deno or Node.js

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'YOUR_SUPABASE_URL'
const supabaseServiceKey = 'YOUR_SERVICE_ROLE_KEY'
const openaiApiKey = 'YOUR_OPENAI_API_KEY'

const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function backfillEmbeddings(tableName: string, batchSize: number = 50) {
  console.log(`Starting backfill for ${tableName}...`)
  
  let offset = 0
  let totalProcessed = 0
  let totalErrors = 0
  
  while (true) {
    // Get batch of records without embeddings
    const { data: records, error } = await supabase
      .from(tableName)
      .select('id, content, category')
      .is('embedding', null)
      .order('created_at', { ascending: true })
      .range(offset, offset + batchSize - 1)
    
    if (error) {
      console.error(`Error fetching records: ${error.message}`)
      break
    }
    
    if (!records || records.length === 0) {
      console.log('No more records to process')
      break
    }
    
    console.log(`Processing batch of ${records.length} records...`)
    
    // Process each record
    for (const record of records) {
      try {
        // Call Edge Function to generate embedding
        const { data: embeddingResponse, error: embeddingError } = await supabase.functions.invoke(
          'guidance',
          {
            body: {
              operation: 'generate_embedding',
              variables: {
                text: record.content,
                source_language: null // Auto-detect
              },
              apiKey: openaiApiKey
            }
          }
        )
        
        if (embeddingError || !embeddingResponse?.success) {
          console.error(`Embedding generation failed for record ${record.id}: ${embeddingError?.message || 'Unknown error'}`)
          totalErrors++
          continue
        }
        
        const embeddingData = embeddingResponse.data
        
        // Update record with embedding
        const { error: updateError } = await supabase
          .from(tableName)
          .update({
            embedding: embeddingData.embedding,
            embedding_model: embeddingData.model,
            embedding_language: embeddingData.detectedLanguage,
            was_translated: embeddingData.wasTranslated,
            embedding_generated_at: new Date().toISOString()
          })
          .eq('id', record.id)
        
        if (updateError) {
          console.error(`Update failed for record ${record.id}: ${updateError.message}`)
          totalErrors++
        } else {
          totalProcessed++
          if (totalProcessed % 10 === 0) {
            console.log(`Processed ${totalProcessed} records...`)
          }
        }
        
        // Small delay to avoid overwhelming the API
        await new Promise(resolve => setTimeout(resolve, 100))
        
      } catch (error) {
        console.error(`Error processing record ${record.id}: ${error.message}`)
        totalErrors++
      }
    }
    
    offset += batchSize
    
    // Longer delay between batches
    await new Promise(resolve => setTimeout(resolve, 1000))
  }
  
  console.log(`Backfill completed for ${tableName}:`)
  console.log(`  - Processed: ${totalProcessed}`)
  console.log(`  - Errors: ${totalErrors}`)
}

// Run backfill for both tables
async function runBackfill() {
  try {
    await backfillEmbeddings('insight_bullet_points', 25)
    await backfillEmbeddings('contextual_insights', 25)
    
    // Update vector indexes after backfill
    const { error: indexError } = await supabase.rpc('create_vector_similarity_indexes')
    if (indexError) {
      console.error(`Error creating vector indexes: ${indexError.message}`)
    } else {
      console.log('Vector indexes updated successfully')
    }
    
  } catch (error) {
    console.error(`Backfill failed: ${error.message}`)
  }
}

// Execute
runBackfill()
```

To run this script:
1. Save as backfill-embeddings.ts
2. Install dependencies: npm install @supabase/supabase-js
3. Set your environment variables
4. Run: deno run --allow-net --allow-env backfill-embeddings.ts

*/

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check embedding distribution by language (after backfill)
SELECT 
    embedding_language,
    COUNT(*) as count,
    ROUND(AVG(CASE WHEN was_translated THEN 1.0 ELSE 0.0 END) * 100, 2) as translation_percentage
FROM insight_bullet_points 
WHERE embedding IS NOT NULL
GROUP BY embedding_language
ORDER BY count DESC;

SELECT 
    embedding_language,
    COUNT(*) as count,
    ROUND(AVG(CASE WHEN was_translated THEN 1.0 ELSE 0.0 END) * 100, 2) as translation_percentage
FROM contextual_insights 
WHERE embedding IS NOT NULL
GROUP BY embedding_language
ORDER BY count DESC;

-- Check embedding dimensions consistency
SELECT 
    'insight_bullet_points' as table_name,
    array_length(embedding, 1) as dimension,
    COUNT(*) as count
FROM insight_bullet_points 
WHERE embedding IS NOT NULL
GROUP BY array_length(embedding, 1)

UNION ALL

SELECT 
    'contextual_insights' as table_name,
    array_length(embedding, 1) as dimension,
    COUNT(*) as count
FROM contextual_insights 
WHERE embedding IS NOT NULL
GROUP BY array_length(embedding, 1);

-- Final progress check
SELECT * FROM get_backfill_progress();

-- =====================================================
-- CLEANUP FUNCTIONS
-- =====================================================

-- Function to remove embeddings (for testing or rollback)
CREATE OR REPLACE FUNCTION clear_all_embeddings()
RETURNS void AS $$
BEGIN
    UPDATE insight_bullet_points 
    SET embedding = NULL, 
        embedding_model = NULL,
        embedding_language = NULL,
        was_translated = NULL,
        embedding_generated_at = NULL;
    
    UPDATE contextual_insights 
    SET embedding = NULL,
        embedding_model = NULL,
        embedding_language = NULL,
        was_translated = NULL,
        embedding_generated_at = NULL;
    
    RAISE NOTICE 'All embeddings have been cleared';
END;
$$ LANGUAGE plpgsql;

-- Use with caution:
-- SELECT clear_all_embeddings();

-- =====================================================