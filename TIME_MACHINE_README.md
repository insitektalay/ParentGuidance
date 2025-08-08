# Time Machine System Implementation

## Overview

This document describes the implementation of the Time Machine system for ParentGuidance - a comprehensive solution for regenerating AI responses with new parameters while preserving historical context and conducting systematic experiments with gold/redline benchmarking.

## Core Features

### 1. Time Machine Regeneration
- **Purpose**: Replay historical situations with new AI parameters while preserving temporal context
- **Key Principle**: When processing a situation, only insights from *prior* situations are available (maintaining historical accuracy)
- **Reset & Replay**: Archives all derived data (guidance, insights, recommendations) and regenerates sequentially

### 2. Gold & Redline Benchmarking
- **Gold Responses**: Manually authored "desired" responses for comparison
- **Redline Responses**: Manually authored "undesired" content to penalize
- **Scoring System**: Multi-metric evaluation including semantic similarity, string overlap, style/tone, and redline penalties

### 3. Experiment System
- **Batch Experiments**: Run multiple configurations automatically
- **Parameter Variation**: Test different models, prompts, temperatures, etc.
- **Leaderboard**: Rank experiments by composite scores
- **Dynamic Prompting**: Auto-generate prompt variations for testing

## Database Schema

### Core Tables

```sql
-- Regeneration tracking
regen_runs (id, family_id, status, config, progress, ...)

-- Benchmark responses
gold_responses (id, situation_id, family_id, version, full_response, response_sections, ...)
redline_responses (id, situation_id, family_id, version, full_response, response_sections, ...)

-- Experiment system
experiment_runs (id, family_id, name, config, status, progress, ...)
experiment_scores (id, experiment_run_id, situation_id, guidance_id, semantic_similarity, composite_score, ...)
```

### Tracking Columns
All derived tables now include:
- `regen_run_id` - Links to the regeneration run that created the record
- `experiment_run_id` - Links to the experiment run that created the record

## Implementation Files

### Models
- `RegenRun.swift` - Core regeneration models and configuration
- `GoldResponse.swift` - Benchmark and experiment models

### Services
- `RegenOrchestrator.swift` - Main regeneration workflow orchestration
- `GoldResponseService.swift` - Gold/redline response management
- `ScoringService.swift` - Multi-metric scoring implementation
- `ExperimentRunner.swift` - Experiment execution and management

### Views
- `RegenAdminView.swift` - Admin interface for configuring and monitoring regeneration

### Database Migrations
- `migrations/time_machine/001_create_regen_runs_table.sql`
- `migrations/time_machine/002_add_regen_run_id_columns.sql`
- `migrations/time_machine/003_create_gold_responses_table.sql`
- `migrations/time_machine/004_create_experiment_tables.sql`
- `migrations/time_machine/005_create_reset_archive_procedure.sql`

## Usage Guide

### 1. Database Setup

```bash
# Run all migrations
psql -d your_database -f run_time_machine_migrations.sql
```

### 2. Basic Regeneration

```swift
// Create orchestrator
let orchestrator = RegenOrchestrator()

// Configure regeneration
let config = RegenConfig(
    modelProvider: "openai",
    guidanceStyle: "warm_practical", 
    guidanceMode: "dynamic",
    similarityThreshold: 0.8,
    familyFilter: nil,
    dateRange: nil,
    determinismSeed: 12345,
    experimentRunId: nil
)

// Start regeneration
try await orchestrator.startRegeneration(
    familyId: familyId,
    config: config
)
```

### 3. Gold/Redline Benchmarking

```swift
// Save gold response
let goldResponse = try await GoldResponseService.shared.saveGoldResponse(
    situationId: situationId,
    familyId: familyId,
    fullResponse: "This is the ideal response...",
    responseSections: ResponseSections(
        title: "Gentle Guidance",
        steps: ["Step 1", "Step 2"],
        tone: "warm_empathetic",
        keyPoints: ["Key point 1", "Key point 2"],
        keywords: nil
    )
)

// Save redline response
let redlineResponse = try await GoldResponseService.shared.saveRedlineResponse(
    situationId: situationId,
    familyId: familyId,
    fullResponse: "This is what we DON'T want...",
    responseSections: ResponseSections(
        title: nil,
        steps: nil,
        tone: nil,
        keyPoints: nil,
        keywords: ["punish", "bad", "wrong"] // Flagged keywords
    )
)
```

### 4. Running Experiments

```swift
// Create experiment
let config = ExperimentConfig(
    promptTemplates: nil,
    modelProvider: "anthropic",
    temperature: 0.7,
    topP: nil,
    seed: 42,
    useEdgeFunction: true,
    guidanceStyle: "analytical_scientific",
    guidanceMode: "fixed"
)

let experiment = try await ExperimentRunner().createExperiment(
    familyId: familyId,
    name: "Claude vs GPT Comparison",
    description: "Compare Anthropic Claude with OpenAI GPT-4",
    config: config,
    runType: .manual
)

// Start experiment
try await ExperimentRunner().startExperiment(experiment.id)
```

## Scoring System

### Metrics

1. **Semantic Similarity** (0.0-1.0)
   - Cosine similarity between guidance and gold response embeddings
   - Weight: 40% (configurable)

2. **String Overlap** (0.0-1.0) 
   - ROUGE-L score measuring text overlap
   - Weight: 30% (configurable)

3. **Style/Tone Score** (0.0-1.0)
   - LLM evaluation against style criteria
   - Weight: 30% (configurable)

4. **Redline Penalty** (0.0-1.0)
   - Semantic proximity to redline content
   - Keyword detection penalties
   - Subtracted from gold alignment scores

### Composite Score Formula

```
composite_score = (gold_score * gold_weight) - (redline_penalty * redline_weight)

where:
gold_score = (semantic * 0.4) + (string_overlap * 0.3) + (style_tone * 0.3)
gold_weight = 0.7 (default)
redline_weight = 0.3 (default)
```

## Historical Context Preservation

### Prior-Only Insight Matching

The system ensures historical accuracy by only matching insights from situations that occurred *before* the current situation being processed:

```swift
// In RelevantInsightsService
func selectRelevantInsightsForHistoricalSituation(
    situationId: UUID,
    priorToDate: Date,  // Only insights before this date
    regenRunId: UUID
) async throws {
    // Fetches insights only from situations created before priorToDate
    // This maintains the historical context that would have existed
    // when the original situation was first processed
}
```

### Sequential Processing

1. Fetch all situations ordered by `created_at ASC`
2. For each situation:
   - Generate guidance with current config
   - Extract insights 
   - Match only against insights from prior situations
   - Tag all new records with `regen_run_id`

## Admin Interface

The `RegenAdminView` provides:

- **Family Selection**: Choose which family to regenerate
- **Configuration**: Set model, style, date ranges, similarity thresholds
- **Progress Monitoring**: Real-time progress bars and statistics
- **Error Handling**: Pause/resume on failures
- **Logging**: Detailed operation logs

## Best Practices

### 1. Testing Strategy
- Start with small family datasets
- Use deterministic seeds for reproducibility  
- Compare results before/after regeneration
- Validate historical context matching

### 2. Gold Response Authoring
- Write responses that represent your ideal AI output
- Include sectioned content (title, steps, tone notes)
- Version responses as requirements evolve
- Cover diverse situation types

### 3. Redline Response Guidelines
- Focus on specific patterns to avoid
- Include problematic keywords/phrases
- Document why content is undesirable
- Test penalty calculations

### 4. Experiment Design
- Vary one parameter at a time for clear attribution
- Use meaningful experiment names and descriptions
- Set appropriate rate limits for API usage
- Monitor composite scores for statistical significance

## Troubleshooting

### Common Issues

1. **RLS Permission Errors**
   - Ensure user belongs to the family being processed
   - Check that service role is used for bulk operations

2. **API Rate Limits**  
   - Adjust delays between processing steps
   - Use batch processing for large datasets
   - Monitor API usage and costs

3. **Historical Context Mismatch**
   - Verify `created_at` timestamps are accurate
   - Check that `fetchAllFamilyInsightsBeforeDate` is working correctly
   - Ensure no future insights leak into historical processing

4. **Scoring Inconsistencies**
   - Validate gold/redline responses are properly saved
   - Check that embeddings are generated correctly
   - Verify scoring weights sum appropriately

### Debugging Tips

- Enable ultra-debug mode in services for detailed logging
- Use PostgreSQL query logs to verify SQL operations
- Check experiment progress JSONB fields for detailed status
- Monitor memory usage during large regenerations

## Future Enhancements

### Planned Features

1. **In-Library Gold/Redline Editing**
   - Rich text editors in SituationDetailView
   - Text selection → Add to Gold/Redline workflows
   - Version history and diff viewing

2. **Dynamic Prompt Generation**
   - AI-generated prompt variations
   - A/B testing framework
   - Automatic prompt optimization

3. **Advanced Scoring**
   - Section-by-section evaluation
   - Custom rubrics per family
   - Statistical significance testing

4. **Export/Import**
   - CSV/JSON export of results
   - Benchmark sharing between families
   - Experiment configuration templates

## Technical Notes

### Performance Considerations

- Regeneration is CPU/API intensive - plan accordingly
- Use connection pooling for database operations
- Consider pagination for large situation sets
- Monitor Supabase usage limits

### Security

- All operations respect RLS policies
- API keys are stored securely in UserDefaults
- Admin views should be restricted to authorized users
- Audit logs track all regeneration operations

### Scalability

- Process families in parallel where possible
- Use queue systems for multiple experiment runs
- Consider read replicas for reporting queries
- Archive old experiment data periodically

---

## Quick Start Checklist

- [ ] Run database migrations
- [ ] Configure API keys  
- [ ] Create test gold/redline responses
- [ ] Run small regeneration test
- [ ] Create first experiment
- [ ] Monitor results in admin interface
- [ ] Scale to full family datasets

For support or questions, refer to the implementation files and test thoroughly in development environments before production use.