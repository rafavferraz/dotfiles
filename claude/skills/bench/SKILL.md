---
name: bench
description: Run benchmarks, analyze performance, and track regressions
allowedTools:
  - Bash(make:*)
  - Bash(bin/bench:*)
  - Bash(python3:*)
  - Bash(tee:*)
  - Bash(mkdir:*)
  - Read
  - Write
  - Glob
  - Grep
---

Analyze benchmark results with scientific rigor. Do not hand-wave — compute actual ratios, verify scaling exponents, and flag anything that deviates from expected behavior. A benchmark suite that looks green but hides regressions is worse than no benchmarks.

## Usage

- `/bench` — build and run all benchmarks, analyze results
- `/bench math` — filter to math benchmarks (`[math]` tag)
- `/bench collision` — filter to collision benchmarks (`[collision]` tag)
- `/bench sim` — filter to simulation benchmarks (`[sim]` tag)
- `/bench compare` — run all and compare against saved baseline
- `/bench --force` — no prompts

## `--force` behavior

When `--force` is passed, the user must not be prompted for any reason — make conservative auto-decisions autonomously and document them in the summary. Only use commands allowed by `.claude/settings.json` in this project directory — do NOT set `dangerouslyDisableSandbox` or attempt to bypass permission rules.

## Pipeline

### 1. Build

Run `make bench`. This compiles with `-O2` and runs all
benchmarks. If a filter argument was provided, run
`bin/bench [<tag>]` after building. **Use a 5-minute
(300000 ms) Bash timeout** for all `make bench` and
`bin/bench` invocations — the default 2-minute timeout
is too short for the full suite.

### 2. Parse and analyze

Use `scripts/bench_analyze.py` to parse Catch2 output
and compute analysis. **Run `make bench` only once** and
save the output to a temp file, then pipe that file into
the analysis script for each operation:

```bash
# Capture output once
make bench 2>&1 | tee /tmp/bench_output.txt

# Basic analysis (table + scaling exponents)
python3 scripts/bench_analyze.py < /tmp/bench_output.txt

# Compare against saved baseline
python3 scripts/bench_analyze.py --compare docs/BENCH_BASELINE.json < /tmp/bench_output.txt

# Save new baseline
python3 scripts/bench_analyze.py --save-baseline docs/BENCH_BASELINE.json < /tmp/bench_output.txt

# JSON output for programmatic use
python3 scripts/bench_analyze.py --json < /tmp/bench_output.txt
```

The script handles:
- **Parsing** — extracts name, mean, std dev, samples from Catch2 output
- **Variance check** — flags benchmarks where std dev > 10% of mean
- **Scaling analysis** — fits `time = c * N^k` via log-log least squares for N-based benchmarks
- **Comparison** — diffs against baseline, flags regressions (>+15%) and improvements (<-15%)

Expected scaling exponents (flag if deviation > 0.3):
- Broad-phase: k ≈ 2.0 (O(N^2))
- Narrow-phase: k ≈ 2.0 (O(N^2))
- Full pipeline: k ≈ 2.0 (O(N^2))
- World tick: k ≈ 2.0 (O(N^2))

### 3. Compare (only for `/bench compare`)

- If `docs/BENCH_BASELINE.json` exists, pass `--compare docs/BENCH_BASELINE.json`
- If no baseline exists, save current results with `--save-baseline` and report "baseline established"

### 4. Report

Create `docs/` if it doesn't exist. Write `docs/BENCH_RESULTS.md` (overwrite if present):

```
# Benchmark Results — YYYY-MM-DD HH:MM

## Summary
Total benchmarks: N | Stable: N | High variance: N | Regressions: N

## Math
| Benchmark | Mean | Std Dev | Variance | Status |
|-----------|------|---------|----------|--------|

## Collision
| Benchmark | Mean | Std Dev | Variance | Status |
|-----------|------|---------|----------|--------|

### Scaling analysis
| Benchmark | N=10 | N=50 | N=100 | N=500 | Exponent (k) | Expected | Status |
|-----------|------|------|-------|-------|--------------|----------|--------|

## Simulation
| Benchmark | Mean | Std Dev | Variance | Status |
|-----------|------|---------|----------|--------|

### Scaling analysis
| Benchmark | N=10 | N=50 | N=100 | Exponent (k) | Expected | Status |
|-----------|------|------|-------|--------------|----------|--------|

## Regressions (vs baseline)
<only if /bench compare and baseline exists>
```

### 5. Save baseline

- After a successful run with no high-variance benchmarks, ask the user if they want to save as baseline
- Save structured data to `docs/BENCH_BASELINE.json` (machine-readable for diffs)
- Ask user before overwriting an existing baseline

### 6. Terminal summary

Print a one-paragraph summary: total benchmarks, stable count, high-variance count, regression count (if comparing), and any scaling anomalies.

## Benchmark files

- `tests/bench/bench_math.cpp` — vec3, mat3, mat4, quat primitives
- `tests/bench/bench_collision.cpp` — contact generation, broad/narrow phase scaling
- `tests/bench/bench_sim.cpp` — integrators, world tick, solver resolution

## Constraints

- Never modify benchmark source files during a run — report results only
- Benchmarks compile with `-O2` for realistic measurements
- Benchmarks are NOT part of `make tests` — opt-in via `make bench`
- Do not draw conclusions from a single run with high variance — suggest re-running
