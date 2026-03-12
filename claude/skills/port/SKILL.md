---
name: port
description: Port and adapt code from older codebases into Lagrange
allowedTools:
  - Bash(make:*)
  - Bash(clang-format:*)
  - Bash(mkdir:*)
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Task
---

Think carefully about how the source code maps onto Lagrange's architecture. The goal is not a line-by-line translation — it's producing code that looks like it was written natively for this codebase. Match every convention, reuse every existing utility, and wire into the architecture cleanly.

## Usage

- `/port <path>` — port a file or directory into the appropriate module
- `/port <path> --target <module>` — port into a specific module (`math`, `body`, `shape`, `bv`, `collision`, `sim`)
- `/port --snippet` — port code from the user's next message (pasted snippet)
- `/port --force` — no prompts

## `--force` behavior

When `--force` is passed, the user must not be prompted for any reason — make conservative auto-decisions on design choices autonomously and document them in the summary. Only use commands allowed by `.claude/settings.json` in this project directory — do NOT set `dangerouslyDisableSandbox` or attempt to bypass permission rules.

## Pipeline

### 1. Ingest

Read the source material (file, directory, or wait for pasted snippet).

Classify what the code implements:

| Category | Target module | Examples |
|----------|--------------|---------|
| Math primitive | `math/` | Vector, matrix, quaternion operations |
| Body component | `body/` | New state component (e.g. angular damping, sleep state) |
| Shape type | `shape/` | BoxShape, CapsuleShape, MeshShape |
| Bounding volume | `bv/` | New BV type or BV construction method |
| Collision routine | `collision/` | New narrow-phase pair, GJK/EPA, contact clipping |
| Integrator / solver | `sim/` | New integrator, constraint solver, joint |

If the source is ambiguous or spans multiple modules, ask the user (unless `--force`, in which case classify by dominant purpose).

### 2. Analyze Lagrange

Before writing anything, read the target module's existing headers and CLAUDE.md (Architecture, Style) to internalize the conventions.

Port-specific checks:
- **Reuse check** — does the source's math already exist in `math/` (Vec3, Mat3, Quat)? Reuse, do not duplicate. Check `types.h` for scalar aliases and type constraints (`FloatingPoint`, `Arithmetic` concepts).
- **Variant registration** — if adding a shape, read `shape/shape.h` for the `Shape<T>` variant definition
- **Dispatch visitors** — if adding a shape, read `collision/broad_phase.h` (`detail::ShapeAabb`) and `collision/narrow_phase.h` for the `constexpr if` lambda dispatch in `std::visit` — add new shape-pair branches there
- **Parallel arrays** — bodies and shapes are indexed by `Uint32` in `sim/world.h` — the source must adapt to this pattern

### 3. Adapt

Transform the source code to match Lagrange conventions (see CLAUDE.md for all naming, template, and style rules).

**Translation:**
- Replace raw math (float[3], custom vec classes, glm types) with Lagrange `Vec3<T>`, `Mat3<T>`, `Quat<T>`
- Replace raw scalar types with `Float32`/`Float64` via template parameter `T`
- One type per header file, matching existing module organization

**Architectural conversions:**
- Inheritance hierarchies → variant-based design (match Lagrange pattern)
- Raw pointers → `Uint32` indices into parallel arrays
- External library dependencies → Lagrange math types (flag if no equivalent exists)

**Scope decisions:**
- If the source has features that don't map cleanly, ask the user what to keep vs. drop
- If `--force`, keep the minimum viable subset and document what was dropped

### 4. Integrate

Wire the new code into the existing architecture:

**If new shape type:**
1. Create `shape/<name>_shape.h` with the shape struct
2. Add to the `Shape<T>` variant in `shape/shape.h`
3. Add AABB computation to `detail::ShapeAabb` in `collision/broad_phase.h`
4. Add narrow-phase dispatch entries in `collision/narrow_phase.h` for all relevant shape pairs
5. Add contact generation function(s) in `collision/generate_contact.h`

**Important:** `bv/` types (`Aabb`, `Sphere`, `Obb`, `Cube`) are standalone bounding-volume utilities — do NOT add them to the `Shape<T>` variant. Only types in `shape/` participate in collision dispatch.

**If new integrator:**
1. Create `sim/integrate_<name>.h` (naming: `integrate_`, not `integrator_`)
2. Add to integrator selection logic in `sim/world.h`

**If new math type:**
1. Create `math/<name>.h`
2. Verify no naming conflicts with existing types

**If new collision routine:**
1. Add to `collision/` with appropriate header
2. Register in narrow-phase dispatch if it handles a shape pair

**If new body component:**
1. Create `body/<name>.h`
2. Wire into `body/rigid_body.h` if it's a core body property

**Umbrella headers:**
- Update `shape/shape.h` when adding new shapes, `lagrange.h` when adding new physics headers
- Do not create new umbrella headers

### 5. Test

Generate tests for every piece of ported code:

- **Unit tests** in `tests/unit/test_<name>.cpp` — constructors, basic operations, edge cases (zero, negative, degenerate inputs)
- **Integration tests** in `tests/integration/` — if the ported code interacts with other systems (e.g. new shape going through broad-phase → narrow-phase → solver)
- **Invariant tests** in `tests/invariant/` — if the code should obey physical laws (conservation of momentum/energy, symmetry, Galilean invariance)

Run verification:
1. `make clean && make` — must compile
2. `make tests` — all suites must pass
3. `make visual` — must compile (if render-related changes)
4. `clang-format -i --style=Google` on all new/modified `.h` and `.cpp` files

### 6. Diff review

Present a structured summary of all changes before finishing:

```
=== Files created ===
  shape/box_shape.h — BoxShape<T> with half-extents, volume, inertia tensor

=== Files modified ===
  shape/shape.h — added BoxShape<T> to Shape<T> variant
  collision/broad_phase.h — added AABB computation for BoxShape
  collision/narrow_phase.h — added Box-Sphere, Box-Ground dispatch entries

=== Source code dropped ===
  - render-specific debug drawing (not applicable to physics module)
  - Custom allocator (Lagrange uses standard containers)

=== Design decisions ===
  - Converted OOP hierarchy to variant member (matches Lagrange pattern)
  - Used half-extents instead of full-extents (matches physics convention)
```

### 7. Summary

Print a terminal summary:

```
Ported: <source description> → <target module(s)>
  Files created: N
  Files modified: N
  Tests added: N (unit: X, integration: X, invariant: X)
  Build: pass/fail | Tests: pass/fail
  Decisions: N (list if --force)
```

## Constraints

- Never commit — the user decides when to commit
- Never modify `lib/glad/` or `docs/`
- Ask before design decisions unless `--force`
- Always produce at least unit tests for ported code
- Run `clang-format -i --style=Google` on all new/modified files
- If ported code conflicts with an existing implementation, flag it — do not silently overwrite
- If the source depends on external libraries not in Lagrange, flag it and propose alternatives using existing Lagrange math types
