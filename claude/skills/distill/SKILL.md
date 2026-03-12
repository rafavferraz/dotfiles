---
name: distill
description: Optimize CLAUDE.md — remove noise, verify claims, minimize token cost
allowedTools:
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Task
---

Think at maximum depth. Every line in CLAUDE.md costs reasoning tokens in every future session. Research shows unnecessary context increases cost by 20%+ and can reduce task success (Gloaguen et al., ETH Zurich, 2026). Calibrate aggressiveness to the intensity level — gentle preserves, moderate balances, aggressive cuts deep.

Optimize CLAUDE.md so it contains the minimum content that prevents the maximum mistakes.

## Usage

- `/distill` — moderate optimization pass (will prompt for decisions)
- `/distill --gentle` — light pass: fix stale claims and exact duplicates only
- `/distill --moderate` — default: apply mistake test, deduplicate, compress
- `/distill --aggressive` — deep pass: cut discoverable content, max compression
- `/distill --force` — no prompts (combines with any intensity level)

## `--force` behavior

When `--force` is passed, the user must not be prompted for any reason — make conservative auto-decisions autonomously and document them in the summary. Only use commands allowed by `.claude/settings.json` in this project directory — do NOT set `dangerouslyDisableSandbox` or attempt to bypass permission rules.

## Intensity levels

Default is `--moderate` when no level is specified.

### `--gentle`

Minimal intervention. Only fix what is provably wrong or redundant:
- Run pipeline steps 1 (count baseline) and 2 (verify claims) — fix stale/incorrect claims
- Run step 4 (deduplicate) — merge exact duplicates only
- **Skip** step 3 (mistake test cuts) and step 5 (compression)
- Do not cut "discoverable" content. Do not compress verbose entries.
- Protected content is fully respected — never touched.

### `--moderate` (default)

Balanced optimization. Apply the full pipeline as defined below (steps 1-7). Cut content that fails the mistake test, deduplicate, and compress verbose entries. Protected content is fully respected.

### `--aggressive`

Maximum token reduction. Full pipeline with stricter thresholds:
- Step 3 uses a tighter cut threshold — content discoverable in **1-2 tool calls** is cut (not just "generic guidance")
- Step 5 compresses aggressively — abbreviations, tighter phrasing, merged entries
- **Protected content can be challenged** — prompt the user before trimming protected items. With `--force`, auto-trim protected content if it fails the strict mistake test.

## The mistake test

The core filter for every line in CLAUDE.md:

> "Would removing this line cause a future session to make a specific, concrete mistake?"

- **YES → keep.** Non-obvious behavior, silent bug risk, convention that contradicts reasonable defaults.
- **YES (efficiency) → keep.** Content that saves 3+ tool calls per session (e.g., project structure map, variant lists). Technically discoverable, but the lookup cost every session outweighs the token cost.
- **NO → cut.** Discoverable structure, generic guidance, redundant with source code.

Always check the **Protected content** section before cutting — protected items override the mistake test.

## What earns its place

- **Non-obvious behaviors** — silent safe division, gravity-as-force, Quat defaults. These cause bugs the agent can't detect by reading code.
- **Conventions that contradict defaults** — no `constexpr`, no `[[nodiscard]]`, `lagrange::` prefix in member bodies. Without these, the agent would do the opposite.
- **Build commands** — not discoverable without reading the Makefile.
- **Project-specific test patterns** — benchmark snapshots, tolerance conventions.
- **Skill/agent tables** — not discoverable from code.

## Protected content — never trim

These items have been explicitly curated. They pass both the mistake test and the efficiency test. Do not remove, merge, or compress them beyond their current form.

- **Project structure map** — the annotated directory listing saves multiple glob/read calls every session. Keep the annotations (e.g., "bv/ — NOT shapes", "render — uses GLM").
- **Intro line context** — gravity direction `{0, 0, -kGravity<T>}`, namespace structure, scalar template param `T`. Referenced constantly, not obvious from any single header.
- **Variant enumerations** (`Shape<T>`, `Integrator<T>`, `Solver<T>`) — exhaustive type lists prevent hallucinating nonexistent variants. Agents cannot reliably extract `std::variant` alias contents from a quick grep.
- **Test suite descriptions** — the semantic distinction between suites (invariant vs integration vs regression) determines where new tests go. Not discoverable from directory names alone.
- **"Things that do not exist" list** — explicitly anti-hallucination. Cannot be discovered from code; must be stated.
- **"Growing list" preamble** in Non-obvious behaviors — instructs future sessions to append new discoveries. Without it, agents won't know to add entries there.
- **"Maintaining this document" section** — instructs future sessions to keep CLAUDE.md current.

## What gets cut

- **Verbose codebase prose** — paragraphs describing what agents can discover via `glob`/`grep`. Exception: keep concise annotated maps that carry non-obvious warnings (see Protected content).
- **Redundant header listings** — if the project structure map already covers it, don't duplicate. Exception: keep variant enumerations that prevent hallucination.
- **Verbose architecture descriptions** — agent reads headers when needed. Exception: keep entries about confusable types (e.g., Transform vs Position) or types that don't exist.
- **Generic coding principles** — the model inherently writes clean, single-responsibility functions.
- **Standard workflows** — git branching, PR flow. The model knows these.
- **Information in source code** — comments, type names, function signatures are already there.

## Pipeline

### 1. Count baseline

Count lines and estimate tokens in current CLAUDE.md.

### 2. Verify claims

Read every factual claim. For each, grep/read actual source to confirm accuracy. Flag stale or incorrect claims.

- Check type definitions, function signatures, default values
- Check claimed behaviors (safe division, gravity formula, Quat defaults, etc.)
- Check that referenced files/headers still exist
- Check that described APIs haven't changed

### 3. Apply the mistake test

**Skipped in `--gentle` mode.** In `--aggressive` mode, use the stricter threshold: cut anything discoverable in 1-2 tool calls.

Go through CLAUDE.md line by line. For each, categorize:

| Category | Action | Example |
|----------|--------|---------|
| Prevents concrete mistake | **Keep** | "Safe division — Vec / T(0) returns unchanged vector" |
| Discoverable via tools | **Cut** | Header inventory, subsystem listings |
| Model already knows this | **Cut** | "Write single-responsibility functions" |
| Redundant with source | **Cut** | Architecture details readable from headers |
| Duplicate within file | **Merge** | Same fact in two sections |

### 4. Deduplicate

Find information stated in more than one section. Keep the single best version in the most logical section.

### 5. Compress survivors

**Skipped in `--gentle` mode.** In `--aggressive` mode, compress maximally — use abbreviations, merge related entries, eliminate all filler.

For entries that pass the mistake test, express them in the fewest words that preserve precision. Remove filler words, combine related items, use terse syntax.

### 6. Rewrite

Apply all changes to CLAUDE.md. Preserve section order.
Validate that the file still reads clearly — terse does
not mean cryptic.

**Max 80 columns** — wrap all prose lines at 80
characters. Tables and code blocks may exceed this when
necessary.

### 7. Report

Print a summary:

```
CLAUDE.md optimization — YYYY-MM-DD

Before: N lines (~N tokens)
After:  N lines (~N tokens)
Reduction: N% fewer tokens per session

Removed (category: count):
  Stale claims:    N
  Discoverable:    N
  Generic:         N
  Redundant:       N
  Duplicate:       N

Kept (N lines) — each prevents a specific mistake:
  Non-obvious behaviors:     N
  Counter-default conventions: N
  Build/test specifics:      N
  Skill/agent references:    N
```
