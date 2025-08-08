# PRD — Parent Guidance Optimization System (PGOS)

## 0. Document metadata

* **Author:** Alex Kerss & Claude
* **Owners:** Product, Eng, Applied Research, Data/ML, Trust & Safety
* **Date:** 2025-08-08
* **Status:** Draft v1.6
* **Reviewers:** Design, QA, Infra, Legal/Privacy, Support

> **What changed in v1.1**
>
> * Grounded the PRD in the existing `RegenOrchestrator` implementation.
> * Replaced global `UserDefaults` toggles with an explicit **Policy Selector** + **ResolvedPolicy** config.
> * Designated current replay loop as the **Ablation Runner** executor.
> * Added Judge integration points and experiment tables.
> * Clarified acceptance criteria and data model deltas.
>
> **What changed in v1.2**
>
> * Grounded the PRD in the existing `ContextualInsightService` (extraction, parsing, batch regeneration, archive flows).
> * Replaced the `context_use_edge_function` flag with policy-driven **ResolvedPolicy.prompt_blocks.context_extraction** fields (provider, enabled, batch_size, delay_ms, thresholds).
> * Added **Embedding & Dedup** component (Edge Function contracts, language stats, similarity actions: insert/fuse/rewrite/drop) and KPIs.
> * Standardised persistence: ensure `family_id`, `regen_run_id`, and `experiment_run_id` are written on *all* saves to `contextual_insights` and `insight_bullet_points`.
> * Added archive table coverage & admin UX for deleted insights; normalised family_id casing.
> * Parameterised 14-section context parsing and UTF-8/schema-fallback behaviour; pipe structured logs to `regen_run_logs`.

> **What changed in v1.3**
>
> * Grounded the PRD in the existing `InsightCleanupService` (orphan detection & cleanup).
> * Added **Insight Hygiene** module: dry-run → commit workflow, guardrails, logging, and RLS-safe shapes.
> * Added `insight_cleanup_runs` table and indexing; normalised `family_id` casing throughout.
> * Added RPC shapes for `find_orphaned_insights` and `cleanup_orphaned_insights`.
> * Added **Data Hygiene** admin tile and acceptance/test items.
>
> **What changed in v1.4**
>
> * Grounded ConversationService and ManualRegenerationService; added Conversation endpoints (analyze, save, translation, favorite/date). Added judge call sites and score persistence. Propagated `experiment_run_id` end-to-end.
>
> **What changed in v1.5**
>
> * Grounded the PRD in the existing `EdgeFunctionService` (Supabase Edge Functions client).
> * Added **Edge Function Client (iOS)** section covering ops: `guidance` (structured + streaming), `analyze`, `framework`, `context`, `coping_strategies`, `translate`, `extract_overall_recommendation`, `generate_embedding`, `check_similarity`, `which_insights_matter`.
> * Introduced policy knobs for guidance path: `{use_function_calling, structure_mode, guidance_style, situation_type}` and for translation/framework generation toggles; removed remaining ad-hoc flags.
> * Documented **SSE semantics** (Vercel AI SDK payloads, `[DONE]` terminator), **UTF-8 validation**, and **typed errors** (`httpError`, `invalidResponse`, `streamingError`).
> * Required run-ID aware logging on all Edge calls; responses feed into judge and persistence seams.

## 1. Summary

PGOS upgrades the current **Time Machine** feature (reset → replay → score) into a **learning control system** that continuously optimises three interdependent components:

1. **Insight Extraction** — turns past situations into reusable, structured nuggets.
2. **Context Selection** — chooses and summarises the right nuggets per new situation.
3. **System Prompt** — assembles instruction/blocks (tone, framework, action template) + selected context to produce guidance.

Following an MLE-STAR–style loop, PGOS introduces a **Prompt Block Registry**, **Ablation Runner** (outer loop), **Block Planner** (inner loop), **LLM-as-Judge** with composite reward, and optional **Ensembling**. Outputs are traceable via `regen_run_id` / `experiment_run_id` and are governed by safety/privacy guardrails.

> **Implementation note:** v1.1 maps these concepts onto the existing orchestrator: replay is the outer executor; per-situation pipeline hooks exist for guidance, optional extraction, and relevant-insights matching. We add judge calls and policy resolution at those seams.

---

## 2. Goals & non-goals

### 2.1 Goals

* Improve per-situation **composite reward** (quality, safety, usefulness) vs baseline.
* Increase **adoption rate** (parent follows advice) and **outcome ratings**; reduce recurrence of recurring issues.
* Provide **explainable** improvements via block-level attribution ("why this won").
* Maintain **historical realism** during replay and strong **safety/PII controls**.

### 2.2 Non-goals

* No end-user UX overhaul beyond required admin/insight surfaces.
* No new clinical capabilities or medical advice; the system remains guidance-only.
* No long-term model training/fine-tuning in v1 (judge/weights only).

---

## 3. Users & personas

* **Operators (Internal Dev/Admin):** run resets, replays, experiments; review leaderboards; rollback.
* **Applied Researchers/PMs:** design blocks, rubrics, judge prompts; interpret metrics.
* **Trust & Safety:** define redlines, thresholds, escalation rules.
* **Support/CS:** needs audit trails for disputed guidance.

---

## 4. User stories

1. *As an operator*, I can reset derived data for a family (date-bounded), replay situations with a candidate configuration, and observe progress/errors.
2. *As a researcher*, I can ablate a single block (e.g., "Similar-Case K") on a sampled slice and see uplift with CIs.
3. *As a PM*, I can compare experiments by composite score and subscores, see "why this won," and promote a policy to serve.
4. *As T&S*, I can set redline thresholds and verify zero safety regressions before rollout.
5. *As Support*, I can fetch exact prompts/params used for a given guidance (audit).

---

## 5. Scope

### In

* Prompt Block Registry (definitions, params, versions).
* Ablation Runner & Block Planner; Ensembling options.
* Judge v1 and composite reward; calibration set and monthly refits.
* Data model extensions; experiment storage; auditability.
* Admin UI tweaks: ExperimentBuilder, Leaderboard, Situation Detail ("Why this won").
* Shadow mode + staged rollout.

### Out (v1)

* Real-time multi-armed bandits (planned v3).
* Cross-family collaborative models beyond global priors.
* Complex visual analytics beyond core dashboards.

---

## 6. Success criteria & KPIs

* **Primary:** Composite reward ↑; Adoption rate ↑; Outcome rating ↑; Recurrence ↓.
* **Quality thresholds:** Context-use ≥ 4.0; Empathy ≥ 4.0; Redline penalty ≤ agreed threshold; Safety incidents = 0.
* **Ops:** p95 latency ≤ target; median tokens/response ≤ budget; replay cost caps met.
* **Personalisation:** ≥X% lift for families with ≥N histories vs. cold start.

---

## 7. Architecture overview

### 7.1 Online serve path

1. **Insight Store →** retrieve family nuggets and global priors (by issue/age).
2. **Context Selector (Block Registry):** retrieve K relevant nuggets (similarity, recency, issue match); summarise to bounded "context pack." If available, incorporate **Which Insights Matter** output to re-rank/select nuggets before summarisation.
3. **System Prompt Builder (Blocks):** Tone & Boundaries, Framework Selector, Action Template, Cultural Norms, + context pack.
4. **Safety/Fidelity Checkers:** context grounding expectation; redline gating; privacy minimisation.
5. **LLM Response → Cardisation** (cards/sections); log provenance.
6. **Feedback Capture:** per-card thumbs; later adoption/outcome logging.

**v1.1 grounding & deltas**

* *Exists now:* serve path applies policy via process-level globals (`UserDefaults`) for provider/style/mode and for toggling extraction/matching. Traceability via `regenRunId`/`experimentRunId` is already threaded through calls.
* *Change:* replace globals with a **Policy Selector** that returns a **ResolvedPolicy** (block versions/params). Pass `ResolvedPolicy` into the orchestration pipeline (guidance, extraction, matching). Maintain run IDs as correlation IDs.

### 7.2 Offline improvement path (Time Machine)

* **Reset & Replay** under experimental configs.
* **Ablation (Outer loop):** probe one block/param vs control; compute uplift.
* **Block Planner (Inner loop):** generate 3–5 constrained plans; replay slice; pick best.
* **Ensembling (Optional):** Best-of-N; Section-wise compose; LLM synthesis; keep if improved & safe.
* **Policy Promotion:** version bump in registry; serve-time policy can switch by cohort.

**v1.1 grounding & deltas**

* *Exists now:* family-scoped resets (full/date-bounded); sequential replay loop with progress/errors; per-situation pipeline: generate guidance → (optional) extract insights → (optional) match relevant insights; operator controls (pause/resume/skip/retry).
* *Change:* (a) Insert **Judge** after guidance (and after any ensemble). (b) Treat the current replay loop as the **Ablation Runner** executor—outer loop varies 1 param; inner loop runs multiple candidate plans. (c) Add ensemble step and re-judge before accepting.

### 7.3 Manual regeneration (current implementation & v1.1 changes)

**Exists now (ManualRegenerationService):**

* Computes situations needing regeneration by selecting `situations` left-joined to `guidance`, scoped by family; maintains an ordered list by `created_at`; enforces **chronological-first** regeneration and blocks duplicates (per-situation in-flight set).
* Calls `ConversationService.generateGuidance(...)` and, based on process-level flags, optionally runs **Contextual Insights**, **Regulation Insights**, and **Relevant Insights** matching.
* Threads `regen_run_id` and (for most calls) `experiment_run_id`; currently Relevant Insights only receives `regen_run_id`.

**Change (v1.1):**

* Replace process flags with the **ResolvedPolicy**: `{context_extraction.enabled, regulation_insights.enabled, relevant_insights.enabled, chronological_enforcement}`.
* Always propagate **both** `regen_run_id` and `experiment_run_id` to all downstream steps, including Relevant Insights (previously only `regen_run_id` was passed).
* Add optional `override.chronology` (default `false`) to allow ablation/planner slices to run out-of-order during experiments; keep chronological enforcement **on** for normal manual runs.
* Surface regeneration events/errors to `regen_run_logs` and include guard-failure messages (e.g., "Please regenerate situations in chronological order…").
* Parameterise `child_name` (policy default "your child") so serve-time can substitute anonymised or personalised values.

### 7.4 Context extraction & dedup service (current implementation & v1.2 changes)

**Exists now (ContextualInsightService):**

* Toggle between **Edge Function** and **Direct API** via `context_use_edge_function` flag; multiple extractors: *context*, *regulation*, *coping strategies*.
* **Parsing:** regulation JSON with fallback to heuristic extraction; **context** parsed into **14 sections**; UTF-8 validation before parse.
* **Persistence:** saves to `contextual_insights` and `insight_bullet_points`; delete flows archive to `deleted_*` tables; some Time Machine inserts omit `family_id`.
* **Batch regen:** clears active rows per family, then processes situations in **batches of 10** with **1s delay**; basic content-level dedup before save.
* **Embedding & similarity:** via Edge Functions; returns language detection/translation info and a `recommendedAction` (`insert|fuse|rewrite|drop`).

**Change (v1.2):**

* Replace feature flag with **ResolvedPolicy.prompt_blocks.context_extraction**: `{ enabled: bool, provider: "edge|direct", batch_size: int, delay_ms: int, similarity_threshold: float, language: "auto|<code>" }`.
* **Always persist** `family_id`, `regen_run_id`, and `experiment_run_id` on *every* write to `contextual_insights` and `insight_bullet_points` (including Time Machine methods).
* Record **language stats** and dedup outcomes per run; emit structured events to `regen_run_logs` (e.g., `utf8_invalid`, `json_fallback_used`, `dedup_action=drop`).
* Normalise `family_id` casing on read/write (store lowercase); enforce RLS-friendly shapes.
* Parameterise the 14-section keys in the registry to allow renames without app updates; add parser versioning.
* Expose `similarity.recommendedAction` handling in policy: `{on_fuse: "merge|keep_new|skip", on_rewrite: "rewrite_then_insert|skip"}`.

### 7.5 Insight hygiene & cleanup (current implementation & v1.3 changes)

**Exists now (InsightCleanupService):**

* Finds orphaned insights and bullet points (e.g., missing/invalid `family_id`, `source_situation_id`, or deleted parents) and can delete/archive them.
* Supports dry-run mode and logs summary stats.

**Change (v1.3):**

* Make hygiene an **operator-run pipeline** with two modes:
  * **Dry-run**: enumerate orphans, compute counts by table/category, no writes; persist a row in `insight_cleanup_runs` with `mode="dry_run"`.
  * **Commit**: perform deletions/moves to `deleted_*` tables; set `mode="commit"`; link each action to `regen_run_id` (if available).
* Always normalise and enforce **lowercased** `family_id` and **RLS-safe filters** on all queries.
* Emit structured logs to `regen_run_logs` per run: `{orphansFoundByTable, actionsTaken, errors}`.
* Guardrails: rate-limit deletes, max batch size, and require explicit operator confirmation for commit.

### 7.6 Scoring & Experimentation (wiring)

**Serve-time scoring.** After guidance (and after any ensemble), call the Judge and persist to `experiment_scores` with `{regen_run_id, experiment_run_id, situation_id, subscores_json, composite, explanations_json}`. Store "Why this won" bullets + highlighted spans.

**Manual regen.** Apply the same judge call + persistence; include in acceptance stats.

**Ablation/Planner loop.** ExperimentRunner executes control vs variants on the same slice; writes `ablation_runs`, `block_plans` (with judge summaries), and optional `ensembles`. Compute mean Δ with bootstrap CI; gate accept if Δ>threshold **and** no safety regression.

**Leaderboard.** Aggregate by experiment and cohort (issue×age), show composite & subscores; link to per-situation "Why this won."

**Safety gate.** Block any variant with higher redline penalty or risk flags; log to `regen_run_logs`.

### 7.7 Edge Function client (current implementation & v1.5 changes)

**Exists now (EdgeFunctionService):**

* Single base URL for Supabase Edge Functions; operations are multiplexed via a JSON body field `operation`.
* **Guidance** supports two modes:
  * **Structured (function calling)** via `generateGuidanceWithFunctionCalling(...)` → expects `{ success:true, format:"structured", data:{...} }` and decodes into a typed response.
  * **Streaming** via `streamGuidance(...)` → Server-Sent Events (SSE) where each `data:` line contains a JSON array of chunks in the Vercel AI SDK format (`[{"type":"text","value":"..."}, ...]`); ends with `data: [DONE]`.
* **Analysis/Framework/Extraction**: `analyze` → `(category, isIncident)`; `framework` → string; `context`/`coping_strategies` → strings.
* **Translation**: `translate` streams text (SSE) rather than batching JSON.
* **Embeddings & Similarity**: `generate_embedding` returns language/translation metadata and vector info; `check_similarity` returns `similarInsights`, `recommendedAction (insert|fuse|rewrite|drop)`, thresholds and stats.
* **Which Insights Matter**: `which_insights_matter` returns a string list of IDs/content deemed relevant.
* All requests authenticate with Supabase session bearer; non-200 → typed `httpError`.

**Change (v1.5):**

* Policy-drive all calls. The orchestrator passes **ResolvedPolicy** fields down to Edge calls:
  * `guidance`: `{ use_function_calling: bool, structure_mode: "fixed|...", guidance_style: string, situation_type: enum }`.
  * `analysis`: `{ enabled: bool, provider: "edge|direct", prompt_version }` (already defined in v1.4).
  * `translation`: `{ enabled: bool, target_language?, smart_on_demand: bool }`.
  * `context_extraction`: `{ provider: "edge|direct", similarity_threshold, language }` (see v1.2).
* **Run-ID propagation in logs**: Every call should log `{regen_run_id, experiment_run_id}` to `regen_run_logs` with request summary and outcome (success/error, duration).
* **SSE contract**: document and enforce `[DONE]` terminator handling; ignore non-`text` chunk types; accumulate in order.
* **UTF-8 guardrails**: all JSON responses validated for UTF-8 prior to parse; failures emit `invalidResponse` with context logged.
* **Framework formatting**: only the framework name is sent upstream (maps to `active_foundation_tools`).

---

## 8. Components & requirements

### 8.1 Prompt Block Registry

* **Must:** store blocks with `{id, name, version, params_json, enabled, change_log}`.
* **Must:** allow enabling/disabling, version pinning by cohort (issue×age band).
* **Should:** support default/global policy and per-family overrides (feature-flagged).
* **Params examples:**
  * Similar-Case Retrieval: `{k:int, recency_days:int, min_sim:float, issue_filter:bool}`
  * Child Profile Summariser: `{max_tokens:int, salience_threshold:float, dedupe:bool}`
  * Action Template: `{steps:int, include_if_then:bool, include_stop_clause:bool}`
* **Implementation note (v1.1):** Supersedes process-level `UserDefaults` flags. A **Policy Selector** resolves block params to a `ResolvedPolicy` injected into the orchestrator.

### 8.2 Ablation Runner

* **Must:** sample a stratified slice (e.g., 200 situations); toggle a single block/param vs control; compute mean Δ and bootstrap CI.
* **Must:** log slice definition, control/test values, uplift stats.
* **Should:** auto-rank next targets by `impact × coverage × staleness`.
* **Implementation note (v1.1):** the existing replay executor becomes the ablation executor. Outer loop constructs two runs (control vs variant) over the same slice definition.

### 8.3 Block Planner

* **Must:** LLM proposes 3–5 constrained plans for the chosen block; guardrails (max latency, token budget, safety rules).
* **Must:** evaluate plans on the same slice; accept best if `Δ > threshold` and no safety regressions.
* **Must:** record trajectory (plan text, metrics, win examples; fail cases).
* **Implementation note (v1.1):** plans are realised as short param sets executed by the existing loop.

### 8.4 Ensembling

* **Modes:** Best-of-N; Section-wise Compose; LLM Synthesis (merge top-2 → re-judge → accept if superior & safe).
* **Must:** store ensemble composition & justification.
* **Implementation note (v1.1):** ensemble runs replay top candidates on the slice; compose outputs; re-judge before commit.

### 8.5 Judge & Reward

* **Subscores:** Gold alignment (embed sim + rubric 1–5); Redline penalty (semantic + keywords); Context-use (span-grounded 1–5); Actionability (1–5); Empathy (1–5); Adoption/Outcome (delayed).
* **Composite:** `0.35*Gold + 0.20*ContextUse + 0.20*Actionability + 0.15*Empathy − 0.10*Redline`.
* **Calibration:** 50–100 item set with human labels; target κ≥0.6; monthly re-fit weights against outcomes.
* **Must:** provide "Why this won" explanations (2–3 bullets + highlighted context spans).
* **Implementation note (v1.1):** add judge call sites after guidance and after ensemble; persist subscores/composite per situation keyed by `regen_run_id` and `experiment_run_id`.

### 8.6 Policy Selector (serve-time)

* **Must:** choose block versions by cohort: global best → family prior (if ≥N histories) → safe baseline if risk ↑.
* **Should:** support feature flags and gradual cohort enablement.
* **Implementation note (v1.1):** replaces process-level globals; returns a `ResolvedPolicy` injected into the orchestrator.

### 8.7 Safety, privacy, fidelity

* **Redline gate:** hard-block above threshold; require "do not proceed if…" in risky topics.
* **Context grounding:** penalise use of context not in the pack; show span highlights to operators.
* **PII minimisation:** summariser strips unnecessary identifiers; "don't echo" rule.
* **Audit:** store prompts & params; attach run IDs to every artefact.
* **Implementation note (v1.1):** redline/context checks execute immediately before returning guidance.

---

## 9. Data model

### 9.1 Tables (delta)

* **regen_runs (exists):** columns include `{id, family_id, status, config_json, progress_json, created_at, completed_at, error_message}`.
  * **Add:** `experiment_run_id text`, `slice_def jsonb`, `mode text` (`ablation|planner|ensemble|baseline`).
  * **Normalize progress writes:** always write full `progress_json` to avoid mixed patch/full updates.

* **New:** `ablation_runs(id, experiment_run_id, block_name, param_key, control_value, test_value, uplift_json, slice_def, created_at)`.

* **New:** `block_plans(id, ablation_run_id, plan_text, params_json, judge_summary_json, picked boolean, created_at)`.

* **New:** `ensembles(id, experiment_run_id, mode, components_json, judge_summary_json, chosen boolean, created_at)`.

* **New:** `experiment_scores(id, regen_run_id, experiment_run_id, situation_id, block_name, plan_id, ensemble_id, subscores_json, composite numeric, explanations_json, created_at)`.

* **New (optional):** `regen_run_logs(regen_run_id, ts, level, message)` for UI streaming.

* **contextual_insights (exists):** add `regen_run_id text`, `experiment_run_id text`, `source_situation_id text`; enforce `family_id` NOT NULL; index `(family_id, created_at)`, `(family_id, category)`.

* **insight_bullet_points (exists):** add `regen_run_id text`, `experiment_run_id text`, `situation_id text`; enforce `family_id` NOT NULL; unique constraint `(family_id, category, content_hash)` (supersedes raw-content unique where applicable).

* **deleted_* (exists):** `deleted_coping_strategies`, `deleted_emotional_regulation_insights`, `deleted_attention_focus_insights`, `deleted_flexibility_social_insights`, `deleted_contextual_insights`; columns `{id, family_id, category, content, deleted_at, deleted_by, source_situation_id}`; index `(family_id, deleted_at)`.

* **Constraints:** keep/migrate `idx_bullet_points_unique_content` → content_hash; standardise lowercased `family_id`.

* **guidance (exists):**
  * **Add/confirm columns:** `original_language text`, `secondary_language text null`, `secondary_content text null`, `overall_recommendation text null`, `translation_status text default 'not_needed'`, `regen_run_id text null`, `experiment_run_id text null`, `created_at timestamptz`, `updated_at timestamptz`.
  * **Indexes:** `(situation_id, created_at)`, `(family_id, created_at)` (if family scoped), `regen_run_id`, `experiment_run_id`.
  * **Constraints:** enforce `created_at ≤ updated_at`; ensure `translation_status ∈ {pending, complete, not_needed, failed}` via CHECK or enum.

* **insight_cleanup_runs (new in v1.3):** as specified; indices `(created_at)`, `(mode, started_at)`, `(family_id, started_at)`.

### 9.2 Indexing & RLS

* Indices: `(family_id, created_at)`, `regen_run_id`, `experiment_run_id`, `(status, created_at)`.
* Enforce family-scoped RLS; operators access via service-role or stored procs.

---

## 10. APIs / Interfaces (shapes only)

### 10.1 Orchestrator inputs (Experiment/Replay)

```json
{
  "family_id": "...",
  "date_range": {"start": "YYYY-MM-DD", "end": "YYYY-MM-DD"},
  "experiment_run_id": "...",
  "mode": "ablation|planner|ensemble|baseline",
  "resolved_policy": {
    "model_provider": "provider/model",
    "temperature": 0.3,
    "top_p": 0.9,
    "seed": 42,
    "prompt_blocks": {
      "similar_case": {"k": 5, "recency_days": 30, "min_sim": 0.65, "issue_filter": true},
      "action_template": {"include_if_then": true, "steps": 5, "include_stop_clause": true},
      "context_extraction": {
        "enabled": true,
        "provider": "edge",
        "batch_size": 10,
        "delay_ms": 1000,
        "similarity_threshold": 0.8,
        "language": "auto"
      },
      "relevant_insights": {"enabled": true},
      "analysis": {"enabled": true, "provider": "edge", "prompt_version": "v1"},
      "translation": {"enabled": false, "smart_on_demand": true}
    }
  }
}
```

> **Implementation note (v1.1):** replaces implicit `UserDefaults` reads. The orchestrator consumes `resolved_policy` directly.

### 10.2 Judge request/response (per situation)

```json
{
  "gold_text": "...",
  "redline_text": "...",
  "context_pack": {"spans": ["..."]},
  "response_text": "...",
  "meta": {"issue_type": "bedtime", "age_band": "7-9"}
}
```

→ returns `{subscores, composite, explanations, risk_flags}`

### 10.3 Manual regeneration (client → orchestrator)

```json
{
  "family_id": "...",
  "situation_id": "...",
  "experiment_run_id": "...",
  "override": {"chronology": false},
  "child_name": "your child",
  "resolved_policy": {"...": "see 10.1"}
}
```

→ returns `{status, regen_run_id, error?}`

**Notes**

* If `override.chronology=false` and the situation is not the earliest needing regeneration, return an error with a human-readable message.
* On success, pipeline executes: guidance → (optional) context/regulation extraction → (optional) relevant-insights match → judge → persist scores.

### 10.4 Edge Function contracts (reference)

> All endpoints are invoked via a single Supabase Edge Function URL with a JSON body containing an `operation` and `variables`. Auth uses a Supabase session bearer. Non-200 → `httpError(status)`. JSON decoding issues → `invalidResponse`. Streaming uses SSE.

**/guidance** (two modes)

* **Structured (function calling)** Request:

```json
{ "operation": "guidance", "variables": {
  "current_situation": "...",
  "child_context": "optional",
  "key_insights": "optional",
  "coping_strategies_home_consequences": "optional",
  "active_foundation_tools": "optional framework name",
  "structure_mode": "fixed|...",
  "guidance_style": "Warm Practical|...",
  "situation_type": "im_just_wondering|..."
}, "apiKey": "...", "useFunctionCalling": true }
```

Response:

```json
{ "success": true, "format": "structured", "data": { "title": "...", "sections": [ ... ] } }
```

* **Streaming (SSE)** Request: same variables, omit `useFunctionCalling`; returns SSE where each line is `data: <json>` and `<json>` is an array of chunks like `[{"type":"text","value":"..."}]`. Terminates with `data: [DONE]`.

**/analyze**

```json
{ "operation": "analyze", "variables": { "situation_text": "..." }, "apiKey": "..." }
```

→ `{ "category": "string?", "isIncident": true|false }`

**/framework**

```json
{ "operation": "framework", "variables": { "recent_situations": "..." }, "apiKey": "..." }
```

→ `string`

**/context**

```json
{ "operation": "context", "variables": { "situation_text": "...", "extraction_type": "general|regulation" }, "apiKey": "..." }
```

→ `string` (14-section text for `general` or regulation JSON text)

**/coping_strategies**

```json
{ "operation": "coping_strategies", "variables": { "longtext": "..." }, "apiKey": "..." }
```

→ `string` (newline-separated)

**/translate** (SSE)

```json
{ "operation": "translate", "variables": { "guidance_content": "...", "target_language": "es" }, "apiKey": "..." }
```

→ SSE text chunks, terminates with `[DONE]`.

**/extract_overall_recommendation**

```json
{ "operation": "extract_overall_recommendation", "variables": { "source_text": "..." }, "apiKey": "..." }
```

→ `string`

**/generate_embedding**

```json
{ "operation": "generate_embedding", "variables": { "text": "...", "source_language": "auto|<code>" }, "apiKey": "..." }
```

→ `{ embedding:[float], detectedLanguage:string, wasTranslated:bool, originalText:string, embeddedText:string, model:string, dimension:int, processingTimeMs:int }`

**/check_similarity**

```json
{ "operation": "check_similarity", "variables": { "embedding": [..], "family_id": "...", "category": "...", "table_name": "contextual_insights|insight_bullet_points", "subcategory": "optional", "similarity_threshold": 0.8 }, "apiKey": "..." }
```

→ `{ similarInsights:[{ id, content, category, similarity_score, was_translated, created_at }], recommendedAction:"insert|fuse|rewrite|drop", deduplicationPolicy:string, highestSimilarity:float, threshold:float, totalFound:int, searchTimeMs:int }`

**/which_insights_matter**

```json
{ "operation": "which_insights_matter", "variables": { "GuidanceText": "...", "InsightList": "..." }, "apiKey": "..." }
```

→ `{ "content": "..." }` (string payload listing selected insights)

**Error semantics & logging**

* Non-200 → `httpError(status)` with body logged.
* UTF-8 invalid/JSON parse → `invalidResponse`.
* Streaming failures → `streamingError(message)`.
* All calls should log a compact request/response summary to `regen_run_logs` with run IDs, duration and size.

### 10.5 Insight hygiene RPCs

**POST /hygiene/find_orphaned_insights** Request:

```json
{ "family_id": "optional", "date_range": {"start":"YYYY-MM-DD","end":"YYYY-MM-DD"}, "limit": 1000 }
```

Response:

```json
{ "stats": { "contextual_insights": 12, "insight_bullet_points": 34, "deleted_*": 0 }, "samples": [{ "table":"contextual_insights", "id":"...", "reason":"missing_parent", "family_id":"..." }], "run_id":"..." }
```

**POST /hygiene/cleanup_orphaned_insights** Request:

```json
{ "run_id": "...", "confirm": true, "max_rows": 1000, "dry_run": false }
```

Response:

```json
{ "deleted": { "contextual_insights": 10, "insight_bullet_points": 20 }, "moved_to_archive": { "deleted_contextual_insights": 8 }, "errors": [], "finished_at": "..." }
```

**Notes**

* All responses include `run_id` (row in `insight_cleanup_runs`) and stream progress to `regen_run_logs`.
* `dry_run=true` performs no writes but records findings in `insight_cleanup_runs.stats_json`.

### 10.6 Conversation service endpoints

**POST /analysis/analyze_situation** Request:

```json
{ "situation_text": "...", "resolved_policy": {"analysis": {"enabled": true, "provider": "edge", "prompt_version": "v1"}}, "api_key": "..." }
```

Response:

```json
{ "category": "optional", "is_incident": false, "provider": "edge|direct", "debug": {"fallback_used": false} }
```

**POST /guidance/save** Request:

```json
{ "situation_id": "...", "content": "...", "overall_recommendation": "...", "regen_run_id": "...", "experiment_run_id": "...", "original_language": "en" }
```

Response: `{ "guidance_id": "..." }`

**PATCH /guidance/:id/translation** Request:

```json
{ "secondary_language": "es", "secondary_content": "optional when completing", "status": "pending|complete|not_needed|failed" }
```

Response: `{ "ok": true }`

**GET /guidance/by_situation** Request:

```json
{ "situation_id": "...", "user_id": "...", "family_id": "...", "preferred_language": "es" }
```

Response: `[Guidance...]` (also triggers smart/on-demand translation if conditions match and policy allows)

**DELETE /situations/:id** Response: `{ "ok": true, "deleted": {"insight_bullet_points": n, "contextual_insights": m, "guidance": k} }` (or structured error with `code` `FK_CONSTRAINT`/`RLS_DENIED`)

**POST /situations/:id/toggle_favorite** → `{ "is_favorited": true }`

**PATCH /situations/:id/date** Request: `{ "created_at": "ISO-8601" }` (server rejects future dates)

---

## 11. UX requirements

### 11.1 Admin: ExperimentBuilder

* Fields: Target Block, Plans (count), Ensemble mode, Model/params/seed, Date range, Slice size.
* Controls: Start, Pause/Resume, Skip/Retry (per situation), Abort.
* Telemetry: progress, errors, tokens/cost (estimate), timings, API calls.

### 11.2 Admin: Leaderboard

* Columns: Composite, Gold, RedlinePenalty, ContextUse, Actionability, Empathy, Block, Plan, Ensemble.
* Facets: Issue type, Age band, Family vs Global.

### 11.3 Situation Detail (internal)

* Panels: Latest Guidance; Original Situation; Gold/Redline editors (versioned, snippet capture); Score strip with subscores.
* "Why this won" module: judge bullets + highlighted context spans.
* Run log stream (from `regen_run_logs`).

### 11.4 Manual regeneration UX (client)

* Show **Needs Regeneration** ordered list; disable Regenerate unless the earliest item is selected (unless operator has override permission).
* Render guard-failure message inline; display per-situation **in-flight** state and last error.
* Surface judge subscores for regenerated items in Situation Detail once available.

### 11.5 Deleted insights archive (admin)

* Views for each archive table with restore/permanent-delete actions and search by category/content/date.
* Inline banner when deleting an item: "This will be archived before removal."
* Restore returns item to active table and removes from archive; log both actions to `regen_run_logs`.
* Family filter defaults to lowercased ID; UI normalises case on input.

### 11.6 Data Hygiene (admin)

* New tile: **Insight Hygiene** with two actions:
  * **Dry-run** (recommended weekly): shows counts by table/category and sample rows; exports CSV.
  * **Commit cleanup**: requires typed confirmation; shows rate-limited progress; links to `insight_cleanup_runs`.
* Permissions: restricted to operator role; audit every action to `regen_run_logs`.
* Safety: always runs under family-scoped RLS; respects lowercased `family_id`.

### 11.7 Conversation flows

* **Situation Analysis:** show provider badge (Edge/Direct) and fallback icon if defaults used; expose policy version.
* **Guidance list:** sort by created date; show translation chip (`pending/complete/not_needed/failed`) and language badges; per-row judge composite (when available).
* **Guidance detail:** dual-language toggle; show source language, translated language, and translation status; allow admin re-queue translation.
* **Situations:** favorite star, editable date (with future-date guard), delete with cascade preview (dry-run first if enabled).

## 12. Evaluation protocol

1. **Calibration set** (50–100 situations) with human rubric labels; tune judge and confirm κ≥0.6.
2. **Ablation slice** (≈200 situations): run outer/inner loops on 1–2 blocks; lock in winners.
3. **Shadow mode** (7–14 days): compute alternatives silently; compare predicted reward and delayed outcomes.
4. **Staged rollout**: 5% → 25% → 100% with drift alarms (drop >0.3σ or safety spike → auto-rollback).

---

## 13. Analytics & dashboards

* **Cohort dashboards:** issue×age; trend lines for composite & subscores; adoption/outcomes lag views.
* **Experiment views:** per-run uplift, CIs, win-rate by situation type; "champion per situation."
* **Safety board:** redline hits, blocked attempts, hallucinated context detections.

---

## 14. Security, privacy, compliance

* PII minimisation and redaction in context packs; retention policy configurable.
* Access controls for admin surfaces; immutable audit trails of prompts/params.
* Export/delete per family; GDPR/APP compliance review.

---

## 15. Performance & cost

* Token budgets per run and per family/day; planner has plan-count caps.
* Caching: embeddings, retrieval, summaries; batch scoring where safe.
* Determinism: seed where supported; log provider model versions.
* **Implementation note (v1.1):** expose current per-situation throttle as a registry param; surface `apiCallsMade` as a cost proxy until token counts are standardised.
* **v1.2:** add `context_extraction.batch_size` and `context_extraction.delay_ms` to policy; record per-batch timings and UTF-8/parse failure counts.

---

## 16. Risks & mitigations

* **Overfitting to history:** rolling holdouts; future-window evaluations.
* **Label noise (Gold/Redline):** versioning, reviewer checklists, periodic cleanups.
* **Judge drift/bias:** monthly recalibration; anchor items; dual-judge sampling.
* **Block interactions:** rotate ablation order; periodic multi-block tests.
* **Feedback sparsity:** use proxy signals (card thumbs/saves) until outcomes arrive; re-weight later.
* **Safety regressions (ensembles):** stricter thresholds; re-judge post-merge.

---

## 17. Roadmap & milestones

### Phase 1 (Weeks 1–2)

* **Prompt Block Registry:** CRUD, versioning + Policy Selector; Judge v1 + calibration set; Ablation mode (outer loop) using existing replay; Leaderboard with subscores + 'Why this won'.
* **Insight Hygiene:** dry-run endpoint + admin tile; commit path behind confirmation.
* **Policy Selector:** Replace UserDefaults with ResolvedPolicy framework.
* **Judge Integration:** Add scoring call sites after guidance generation.

### Phase 2 (Weeks 3–6)

* Block Planner (constrained plans & selection).
* Best-of-N ensembling; judge gating.
* Shadow mode infra; drift alarms; rollback.

### Phase 3 (Weeks 7–10)

* Section-wise compose & LLM synthesis ensembles.
* Refit reward weights using adoption/outcomes.
* Serve-time Policy Selector (cohort aware).

### Phase 4 (Weeks 11+)

* Contextual bandits online; continuous learning.
* Richer insight extractors (e.g., transition sensitivity timelines).
* Safety automation (pattern detectors; escalation tips).

---

## 18. Acceptance criteria (v1 "first win")

* ≥0.4σ composite uplift on a 200-situation slice for ≥1 block with **no safety increase**.
* Shadow week confirms uplift; p95 latency on-par; cost within budget.
* Rollout 5%→25% with stable KPIs; "Why this won" available in UI.
* **v1.1 add:** Judge invoked for ≥95% of replayed situations; subscores & composite persisted per situation, keyed by `regen_run_id` and `experiment_run_id`.
* **Manual regeneration:** chronology enforced by default; override respected only for ablation/planner runs; 0 duplicate-regen conflicts.
* **v1.2 add:** 100% of `contextual_insights` and `insight_bullet_points` rows created during replays include `family_id`, `regen_run_id`, and `experiment_run_id`.
* **v1.2 add:** Context extraction obeys `ResolvedPolicy` (provider, batch_size, delay_ms, thresholds); dedup actions logged and match policy mapping.
* **v1.3 add:** Hygiene dry-run enumerates orphans with ≤1% false positives on calibration families; commit removes/moves rows with zero RLS violations.
* **v1.3 add:** `insight_cleanup_runs` populated for 100% hygiene executions with stats and errors recorded; `regen_run_logs` includes per-table counts.
* **v1.4 add:** 95%+ of new guidance rows include `{regen_run_id, experiment_run_id}`; translation status transitions are consistent (no stuck `pending` >24h); analyze-situation honors policy and logs provider/fallback; delete previews and cascades succeed without RLS violations on calibration families.
* **v1.5 add:**
  * Structured guidance path returns `{success:true, format:"structured"}` for ≥95% of `use_function_calling=true` invocations; streaming guidance terminates with `[DONE]` and yields no parser errors on the calibration set.
  * All Edge responses pass UTF-8 validation; non-200 responses are mapped to typed errors and logged with run IDs.
  * Embedding/Similarity contracts respected (dimension present; `recommendedAction` in {insert,fuse,rewrite,drop}).

## 19. Test plan (QA)

* **Functional:** CRUD on blocks; run ablation/planner/ensemble; replay idempotency; resume after failure; RLS boundaries.
* **Scoring:** judge subscores stable on calibration set; inter-rater κ checks.
* **Safety:** inject known redlines; verify gating; context hallucination detector flags.
* **Perf:** load tests on replay; token/cost monitoring; caching efficacy.
* **UX:** Admin flows, error handling, progress telemetry, export CSV/JSON; run log streaming.
* **Manual regen:** earliest-first guard, duplicate-regen guard, override behavior (experiments only), error surfacing, propagation of `experiment_run_id` to all steps.
* **Extraction parsing:** 14-section parser unit tests (happy/sad paths), regulation JSON + fallback coverage; UTF-8 invalid input tests.
* **Dedup pipeline:** similarity thresholds, `recommendedAction` mapping (`insert|fuse|rewrite|drop`), language stats aggregation; false-positive and false-negative cases.
* **Persistence:** inserts include `family_id` + run IDs; archive flows move rows to correct `deleted_*` tables; case-normalised `family_id` passes RLS.
* **Insight hygiene:** dry-run vs commit parity; max batch guard; RLS enforcement; lowercased `family_id` normalization; archive integrity (restore path); failure injection (permission errors, partial failures) with retries/logging.
* **Edge Function client:**
  * **SSE**: simulate chunked JSON arrays and `[DONE]`; verify accumulator yields exact concatenation and finishes.
  * **Structured guidance**: mock `{success:false}` and missing `data` → assert `invalidResponse`; happy path decodes to typed model.
  * **UTF-8**: fuzz invalid byte sequences; ensure guard and error mapping.
  * **Analyze**: missing fields vs both fields present; default/fallback handling.
  * **Embedding/Similarity**: dimension/type checks; policy threshold respected; `recommendedAction` integration path.
  * **Translate**: long inputs stream without deadlocks; failure returns `httpError` and leaves status consistent.

## 20. Open questions

* Thresholds for "> +0.5σ" acceptance — should this vary by cohort size/variance?
* Minimum traffic for family-level priors before enabling personalised policy.
* Governance for updating Gold/Redline benchmarks (review cadence, DRI).
* Do we expose partial metrics to end users (e.g., "why you saw this advice")?
* Should `experiment_run_id` be required for *all* replays (incl. baseline) for joinability?

---

## 21. Glossary

* **Nuggets:** structured insights from past situations (traits, strategies, outcomes).
* **Context pack:** bounded, summarised nuggets injected into the prompt.
* **Blocks:** independently tunable prompt/pipeline sections (tone, retrieval K, etc.).
* **Ablation:** experiment toggling one block/param vs control to estimate impact.
* **Planner:** LLM proposing small changes within a block with constraints.
* **Composite reward:** weighted score combining subscores and penalties.

---

## 22. Appendix — Example block parameter sets

* **Similar-Case Retrieval (baseline):** `{k:3, recency_days:30, min_sim:0.65, issue_filter:true}`
* **Action Template (baseline):** `{steps:5, include_if_then:true, include_stop_clause:true}`
* **Child Profile Summariser (baseline):** `{max_tokens:120, salience_threshold:0.5, dedupe:true}`

---

## 23. Decision log (to fill during review)

* TBD - To be filled during implementation review sessions

---

## 24. Implementation Notes (Based on Current Codebase)

### Existing Components Mapped to PGOS

1. **RegenOrchestrator** → **Ablation Runner & Orchestrator**
   - Already handles reset, replay, and progress tracking
   - Needs: Policy injection, judge integration, ensemble support

2. **ManualRegenerationService** → **Manual Regeneration Pipeline**
   - Already enforces chronological ordering
   - Needs: ResolvedPolicy integration, experiment_run_id propagation

3. **ContextualInsightService** → **Insight Extraction & Dedup**
   - Already has embedding/similarity and dedup logic
   - Needs: Policy-driven configuration, consistent run ID tracking

4. **InsightCleanupService** → **Insight Hygiene**
   - Already has dry-run and commit modes
   - Needs: Integration with regen_run_logs, normalized family_id

5. **ScoringService + RedlinePenaltyCalculator** → **Judge & Reward**
   - Already calculates composite scores
   - Needs: Integration into regeneration pipeline, explanation generation

6. **EdgeFunctionService** → **LLM Interface**
   - Already handles all AI operations
   - Needs: Policy-driven parameters, consistent logging

7. **ExperimentRunner + ExperimentExportService** → **Experiment Management**
   - Already runs experiments and exports results
   - Needs: Integration with ablation/planner modes

### Migration Path

1. **Phase 0 (Current State)**: Time Machine with basic regeneration
2. **Phase 1**: Add ResolvedPolicy, replace UserDefaults
3. **Phase 2**: Integrate Judge, add scoring persistence
4. **Phase 3**: Add ablation/planner modes to orchestrator
5. **Phase 4**: Add ensemble support and promotion pipeline