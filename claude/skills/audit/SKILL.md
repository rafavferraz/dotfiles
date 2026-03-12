---
name: audit
description: Full codebase audit — physics correctness, style, and code quality
allowedTools:
  - Bash(make:*)
  - Bash(clang-format:*)
  - Bash(clang-tidy:*)
  - Bash(mkdir:*)
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Task
---

Think at maximum depth. Be exhaustive, skeptical, and thorough — treat this as a peer review where correctness failures ship to production. Question every formula, every assumption, every edge case. Do not skim.

Audit the entire codebase and produce a prioritized diagnosis report.

## Usage

- `/audit` — full audit (will prompt for tool permissions)
- `/audit --force` — full audit, no prompts

## `--force` behavior

When `--force` is passed, the user must not be prompted for any reason — make conservative auto-decisions autonomously and document them in the summary. Only use commands allowed by `.claude/settings.json` in this project directory — do NOT set `dangerouslyDisableSandbox` or attempt to bypass permission rules.

## Pipeline

### 0. Read project conventions

Read `CLAUDE.md` in full before auditing. Pay special
attention to **"Conventions that contradict defaults"**
and **"Non-obvious behaviors"**. Behaviors documented
there are intentional design decisions — do NOT flag
them as bugs, hazards, or code quality issues. Examples
include safe-division returning unchanged vectors,
`Quat()` defaulting to identity, gravity applied as
force (not acceleration), `ImpulseEngine` being
intentionally crude, unbounded positional correction,
O(n²) broadphase, `NarrowPhase` silently skipping
unhandled pairs, and `Plane::Intersect()` returning
true for back-side objects. If a finding matches a
documented behavior, skip it entirely.

### 1. Build

Run `make clean && make && make visual`. Record pass/fail for each target.

### 2. Test

Run `make tests`. Record per-suite results (cases, assertions, pass/fail).

### 3. Style

- Run `clang-format --dry-run --style=Google -Werror` on all `.h` and `.cpp` files (exclude `lib/`)
- Run `clang-tidy` on all source files (exclude `lib/`)
- Record every violation with file:line

### 4. Physics correctness

This is the highest-priority pass. Read every header in `math/`, `body/`, `sim/`, `collision/`, `shape/`, `bv/`. For each, verify:

- **Formulas** — integration, impulse resolution, contact generation, inertia tensors, broadphase/narrowphase logic match standard rigid-body dynamics
- **Numerical stability** — division-by-zero guards, epsilon comparisons, normalization of near-zero vectors
- **Edge cases** — zero mass, infinite mass, coincident bodies, degenerate shapes, resting contact
- **Conservation** — momentum and energy conservation where expected (elastic collisions, no-gravity scenarios)
- **Sign conventions** — normals point from A to B consistently, `penetration < 0` means overlap

Flag anything that would produce wrong simulation results.
Cross-check every potential finding against CLAUDE.md's
"Non-obvious behaviors" section — if the behavior is
documented as intentional, it is not a bug.

### 5. Test audit

Read every test file in `tests/`. Evaluate:

- **Coverage** — identify public methods, code paths, and edge cases that have no corresponding test
- **Accuracy** — verify test assertions match expected physics results (e.g. a gravity-only free-fall test should check `v = g*t`, not arbitrary values)
- **Logical soundness** — flag tests that always pass, test implementation details instead of behavior, or use tolerances so loose they mask real bugs
- **Integration gaps** — review `tests/integration/` for missing multi-system scenarios (e.g. collision + impulse resolution, broadphase feeding narrowphase, multi-body stacking stability)
- **Proposed tests** — for each gap found, describe the test: what it sets up, what it asserts, and why it matters for a correct physics engine

Report under its own priority section in the diagnosis.

### 6. Benchmark coverage

Read the benchmark files in `tests/bench/` (`bench_math.cpp`, `bench_collision.cpp`, `bench_sim.cpp`) and cross-reference against the public API in `math/`, `body/`, `sim/`, `collision/`, `shape/`, `bv/`. For each module, evaluate:

- **Operation coverage** — which public functions/methods have a corresponding benchmark? Which performance-critical operations are missing?
- **Type coverage** — benchmarks should cover both `f` (float) and `d` (double) suffixed types where performance may differ. Flag types with no benchmarks at all.
- **Scenario coverage** — are there benchmarks for the hot paths that matter in a real simulation tick? (e.g. if `ImpulseEngine::Resolve` is called every frame, it needs a benchmark)
- **Scaling coverage** — do N-based scaling benchmarks exist for operations whose cost grows with object count? Flag O(N^2) algorithms that lack scaling benchmarks.
- **Missing benchmarks** — for each gap, propose a specific benchmark: what it measures, why it matters for performance, and which file it belongs in

Report as a table in the diagnosis:

```
| Module | Benchmarked | Missing | Priority |
|--------|-------------|---------|----------|
```

Priority: **high** for hot-path operations called every tick, **medium** for operations called per-body or per-contact, **low** for one-time setup operations.

### 7. Code quality

Linters handle formatting and mechanical rules. This pass focuses on what they can't catch:

- **Clarity** — functions doing too many things, unclear names that require reading the body to understand, non-obvious control flow
- **Simplicity** — over-engineered abstractions, indirection without payoff, code that could be half the lines
- **Dead weight** — unused functions, unreachable branches, parameters that are always the same value
- **Maintainability** — tight coupling between unrelated modules, hidden dependencies, magic numbers without context
- **Refactoring opportunities** — duplicated logic that should be extracted, types that have grown beyond a single responsibility, call chains that could be simplified
- **Design changes** — propose structural improvements when the current architecture fights the code (e.g. a variant that should be a hierarchy, a flat loop that should be a spatial query, a component split that would improve testability)

Cross-check every potential finding against CLAUDE.md's
"Conventions that contradict defaults" and "Non-obvious
behaviors" sections — if the behavior or style is
documented as intentional, do not flag it.

### 8. Report

Create `docs/` if it doesn't exist. Write `docs/DIAGNOSIS.md`
(overwrite if present). Follow this exact layout:

```markdown
# Diagnosis — YYYY-MM-DD HH:MM

Build: main ✓/✗ | visual ✓/✗ (notes if any)

Tests:

| Suite | Tests | Passed | Failed | Assertions |
|-------|-------|--------|--------|------------|
| unit | N | N | 0 | N |
| integration | N | N | 0 | N |
| invariant | N | N | 0 | N |
| determinism | N | N | 0 | N |
| regression | N | N | 0 | N |
| stress | N | N | 0 | N |
| **total** | **N** | **N** | **0** | **N** |

## P0 — Physics bugs

No P0 issues found. (or numbered list)

## P1 — Numerical hazards

1. `file/path.h:line-line` — **Bold summary title.**
   Detailed explanation of the hazard, why it matters,
   and what conditions trigger it. Include concrete
   values (e.g. thresholds, epsilon magnitudes) where
   relevant.

## P2 — Test gaps

1. `file/path.h:line-line` — **Bold summary of what is
   not tested.** Explanation of what the gap is and why
   it matters.

## P2.5 — Benchmark gaps

| Module | Benchmarked | Missing | Priority |
|--------|-------------|---------|----------|
| `module/path` | What is covered | What is missing | high/medium/low/— |

Priority: high = hot-path per-tick, medium = per-body
or per-contact, low = one-time setup, — = fully covered.

## P3 — Style violations

N clang-format violations across M files (note scope):

1. `file.cpp:lines` — brief description of violation
2. ...

Summary line (e.g. "All production headers pass clean.")

## P4 — Code quality

1. `file/path.h:line` — **Bold summary.** Detailed
   explanation of the issue, why it matters, and a
   concrete suggestion for improvement.
```

Format rules:
- **Numbered items** — each finding is a numbered list
  item, not bullets.
- **Bold title** — each item starts with a **bold
  sentence** summarizing the finding, followed by a
  detailed explanation.
- **Backtick paths** — file paths and code references
  use backticks: `` `file/path.h:line` ``.
- **Concrete details** — include specific values,
  thresholds, line numbers, and code snippets. Never
  write vague findings.
- **P2.5 table** — benchmark gaps use a markdown table,
  not a numbered list. One row per module. Use `(none)`
  for unbenchmarked modules and `(fully covered)` or
  `(adequate)` when no gaps exist.
- **P3 grouping** — group style violations by file,
  listing affected lines in a single entry.
- **Empty sections** — if no issues found, write
  "No P0 issues found." (not omit the section).
- **No priority table** — the section headers already
  encode priority. Do not include a legend table.

### 9. Summary

Print a one-paragraph terminal summary: build status, test status, issue counts by priority.
