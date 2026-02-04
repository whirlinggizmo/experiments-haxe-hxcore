# Scripting Overhaul Handoff Doc

## 1) Goal Summary
Rework `hxcore.scripting` to make cppia and JavaScript viable hot-code-reload (HCR) scripting targets for development. Developers should be able to edit scripts live during development, while preserving a clean path to compile those same scripts into the shipped product without code changes. External scripts must be able to override internal scripts to enable modding.

## 2) Non-Goals / Explicit Out of Scope
- Removing cppia or JavaScript target support.
- Replacing Haxe with another scripting language.
- App-specific solutions when a generic `hxcore` utility would be appropriate.

## 2a) Compatibility Assumption
- There are no current external consumers of `hxcore` or `hxcore.scripting`, so backwards compatibility is **not required**. API changes are allowed if they improve the architecture or reliability.

## 3) Current Behavior Snapshot (Must Preserve)
- Scripts derive from `hxcore.scripting.Script` and are managed by `ScriptHost`.
- Script lifecycle: load, reload, unload, update, fixedUpdate.
- External scripts can override internal scripts when enabled.
- Hot reload and hot compile are available on `sys` + `scriptable` targets.

## 4) Target Behavior / Desired Changes
- Make HCR behavior reliable and predictable for both cppia and JS targets.
- Make internal vs external resolution rules explicit and consistent.
- Ensure build outputs and watcher inputs are aligned with actual runtime paths.
- Maintain a single script source codebase that works for dev HCR and for release builds.

## 5) Architecture Constraints
- Must support cppia and JavaScript scripting targets.
- Must preserve the ability to compile scripts into the main app binary for release.
- External scripts must be able to override internal scripts to support modding.
- The system must support both “compile on change” and “reload on compiled change.”
- Prefer extending `hxcore` utilities for cross-project reuse when feasible.
- Additional investigation required for environments without file I/O (e.g., wasm or browser JS) to determine feasible script update delivery (fetch/push) and HCR support.
- Use Haxe target-specific file naming (`foo.cpp.hx`, `foo.js.hx`, `foo.hx`) to separate target logic where appropriate.
- `#if`/`#end` is acceptable, but if it leads to heavy branching or spaghetti, prefer clean file separation by target.

## 6) Public API Surface (Must Preserve)
- `hxcore.scripting.Script`
- `hxcore.scripting.ScriptHost`
- `hxcore.scripting.ScriptLoader` (cpp/js variants)
- `hxcore.scripting.ScriptCompiler`
- `hxcore.io.FileWatcher`
- Entry points in examples (e.g., `ScriptTest` options)

## 7) Internal APIs (Allowed to Change)
- Script loading cache behavior
- File watcher implementation details
- Macro injection strategy for namespace remapping
- Export class filtering logic and tooling

## 8) Watcher Model Requirements
- Hot compile: `.hx` changes recompile into `.cppia`/`.js` and trigger reload.
- Hot reload: compiled output changes trigger reload without restarting host.
- Must support both relative and absolute script roots reliably.
- Must debounce or avoid duplicate reloads when multiple changes occur quickly.

## 9) Script Compilation Requirements
- Use Haxe cppia and JavaScript targets for HCR.
- Ensure output paths align with runtime loader paths.
- Ensure namespace injection avoids collisions with internal classes.
- External scripts must be able to override internal scripts (modding).
- Ensure `export_classes.info` is used correctly to avoid duplicate classes.

## 10) Script Host / Runtime Lifecycle
- `ScriptHost` must set script context (`ctx`) and host before invoking script methods.
- `load -> _baseLoad`, `reload -> _baseReload`, `unload -> _baseUnload`.
- Script lifecycle should be consistent across internal and external scripts.

## 11) Error Handling / Logging
- Clear logging when external scripts are missing or fail to compile.
- Clear logging when hot reload/compile is disabled by platform/define.
- Avoid noisy logs on normal watcher polling.

## 12) Compatibility Risks
- Changes to namespace injection can break external overrides.
- Changes to `export_classes.info` filtering can cause missing base classes in cppia.
- Path handling changes can break watcher matching on existing projects.

---

# Special Considerations: cppia + export_classes.info

When generating cppia, Haxe uses `export_classes.info` to avoid compiling classes that already exist in the host application. This prevents duplicate classes and symbol collisions. However, `export_classes.info` may include classes that must still be present in the cppia output (for example, a base `Script` class or other shared runtime classes). The overhaul must explicitly handle filtering or altering this list so that required classes are included in generated cppia, even if they exist in the host build.

This is a critical requirement: class exclusion must be deliberate and configurable, not incidental.

---

# Test Plan

## TDD Approach
- Use `utest` as the primary test framework.
- Start by writing tests for watcher/compile/reload and export class filtering before refactoring implementation.

## A) Unit Tests
- FileWatcher: filter matching, add/modify/remove detection, ignored paths.
- Path handling: relative vs absolute roots produce correct matching behavior.
- Namespace injection: generated class name resolution and fallback.
- Export class filtering: required base classes are preserved in cppia output.

## B) Integration Tests
- Hot compile: edit `.hx` -> `.cppia` or `.js` changes produced.
- Hot reload: compiled output changes trigger reload without crash.
- External override: external script replaces internal script without code changes.

## C) Regression Tests
- Existing example(s) still run with internal scripts only.
- Existing example(s) still run with external scripts enabled.
- JS target HCR still behaves as expected.

## D) Performance / Stability
- Watcher remains stable under many script files.
- Repeated reloads do not leak memory or leave stale references.

---

# Acceptance Criteria (Definition of Done)
- HCR works for cppia and JS targets with documented steps.
- External scripts override internal ones predictably.
- `export_classes.info` handling ensures required shared classes are included in cppia.
- All tests in this document pass.
- Documentation updated to describe the workflow for dev HCR vs release builds.

---

# Notes / References
- `examples/scripttest/build.hxml`
- `src/hxcore/scripting/*`
- `src/hxcore/io/FileWatcher.hx`
- `src/hxcore/macros/NamespaceInjector.hx`
- `src/hxcore/macros/ExportClassesInfo.hx`
