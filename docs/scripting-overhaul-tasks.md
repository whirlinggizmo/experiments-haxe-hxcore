# Scripting Overhaul Tasks

Date: 2026-04-28

This task list is the operational companion to:

- `docs/scripting-overhaul.md`
- `docs/scripting-overhaul-proposal.md`
- `docs/library-audit-2026-04.md`

Use this file for implementation progress, sequencing, and cleanup tracking.
Use the overhaul docs for architecture, constraints, and design intent.

## Status

- [ ] Phase 1: Split `ScriptLoader.cpp.hx` responsibilities without changing supported behavior
- [ ] Phase 2: Tighten script host/environment/state flow
- [ ] Phase 3: Reconcile or explicitly demote non-cpp scripting paths
- [ ] Phase 4: Reduce surrounding runtime surface that obscures the scripting model

## Phase 1: Loader Decomposition

Goal: break up the current cpp scripting loader into smaller units while preserving the current cppia feature set and test coverage.

- [x] Inventory current `ScriptLoader.cpp.hx` responsibilities and mark target extraction boundaries
- [x] Extract script path and generated-name resolution into a dedicated helper/service
- [x] Extract compile invocation to clarify the compile boundary
- [x] Extract watcher orchestration into a dedicated coordinator/service
- [ ] Keep loader focused on module/class loading and instance creation
- [x] Keep override resolution explicit and centralized
- [x] Preserve current `ScriptRuntime` public entry points during the split
- [x] Preserve current cpp tests during each extraction step

## Phase 2: Host and State Tightening

Goal: make script lifecycle and runtime state handoff explicit instead of relying on hidden mutable `Dynamic` context.

- [ ] Define the desired script environment/state model
- [ ] Decide what persists across reload: host, state, event listeners, explicit stash, or some combination
- [ ] Replace ad hoc context mutation in `ScriptHost` with a clearer environment boundary
- [ ] Reconcile `Entity.ctx` with the actual script host state model
- [ ] Unify initial load and reload lifecycle flow as much as possible
- [ ] Add tests for any changed lifecycle/state semantics

## Phase 3: Target Support Clarity

Goal: stop implying feature parity where it does not exist.

- [ ] Audit the JS loader against the cpp loader contract
- [x] Add a JS-target compile/runtime regression lane
- [ ] Decide whether JS HCR remains in scope now or is explicitly downgraded to experimental/stale
- [ ] Add capability checks or support-level documentation to config/runtime setup
- [ ] Ensure unsupported target combinations fail clearly

## Phase 4: Surface Area Reduction Around Scripting

Goal: reduce adjacent runtime code that makes the scripting story harder to understand.

- [ ] Decide whether `Entity` remains the primary script attachment model
- [ ] Collapse or demote `ActorRegistry` if it remains redundant
- [ ] Reassess `EntityManager` and `SystemRegistry` in light of the scripting runtime design
- [ ] Demote or remove `Stage` from the default library story unless rebuilt
- [ ] Demote or remove `App` from the default library story unless rebuilt
- [ ] Separate scripting-critical macros from optional native interop tooling in docs and package structure

## Tracking Notes

- Current highest-leverage refactor target: `src/hxcore/scripting/ScriptLoader.cpp.hx`
- Added shared resolver: `src/hxcore/scripting/ScriptPathResolver.hx`
- Added direct compile entry point: `ScriptCompiler.compileCppia(...)`
- `ScriptWatcher.hx` now owns watcher lifecycle, dedupe, unload, dispose, and tick behavior
- `ScriptWatcher.hx` now uses `DebouncedQueue` directly; `ScriptChangeCoalescer.hx` was removed
- `HotCompileScope` now lives with `ScriptConfig`; `ScriptInfo` now lives with `IScriptLoader`
- `ScriptLoader.cpp.hx` now uses explicit internal/external resolution and cache replacement helpers instead of mixing fallback logic inline
- shared `ScriptRuntime.hx` is back to target-agnostic orchestration
- cpp/cppia hot compile + hot reload orchestration now lives in `src/hxcore/scripting/ScriptLoader.cpp.hx`
- Shared scripting/path layer now typechecks in a minimal JS compile probe again
- Current strongest validated path: `cpp + scriptable + cppia`
- Current stale path: `src/hxcore/scripting/ScriptLoader.js.hx`
- Current baseline verification commands:
  - `haxe hxml/tests.hxml`
  - `haxe hxml/tests-cpp.hxml`
  - `haxe hxml/tests-js.hxml`

## Working Rule

After each meaningful refactor step:

1. Update this task file.
2. Run the relevant tests.
3. Update `docs/scripting-overhaul.md` only if the intended architecture or requirements changed.
