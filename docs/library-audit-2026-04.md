# hxcore Library Audit

Date: 2026-04-28

## Scope

This audit is based on the current source tree, examples, and test suite in this repository.

The immediate goal is to:

1. Map the major systems in the library.
2. Identify which ones are real, tested, and worth investing in.
3. Identify which ones are scaffolding, stale, or misleading.
4. Outline how to tighten the scripting stack without reducing current feature capability.

## Executive Summary

`hxcore` is not a single coherent engine yet. It is a mixed repository containing:

- One mature-enough subsystem: `hxcore.scripting` on `cpp + scriptable`.
- A set of useful support utilities: path handling, debounce/coalescing, logging, file watching.
- Several prototype runtime surfaces: `app`, `stage`, `actor`, `ecs`, `scene`, `camera`, `ui`.
- A large macro/interop area with uneven relation to the rest of the repo.
- An embedded `flecs_wrapper` subtree that behaves more like a separate package/vendor subtree than part of the core library.

The practical conclusion is:

- The scripting stack is the only subsystem with clear architectural direction and end-to-end tests.
- Most non-scripting runtime layers should be treated as experimental scaffolding, not stable library architecture.
- Because there are no consumers, this is a good time to reduce surface area aggressively and define a cleaner “real core”.

## Current Systems

### 1. Scripting

Files:

- `src/hxcore/scripting/*`
- `src/hxcore/io/FileWatcher.hx`
- `src/hxcore/util/ExportClassesInfoFilter.hx`
- `src/hxcore/macros/NamespaceInjector.hx`
- `src/hxcore/macros/ExportClassesInfo.hx`

Responsibilities:

- Script configuration via `ScriptConfig`.
- Runtime orchestration via `ScriptRuntime`.
- Host/lifecycle management via `ScriptHost`.
- Target-specific loading via `ScriptLoader.cpp.hx` and `ScriptLoader.js.hx`.
- Hot compile and hot reload support.
- External override support.
- Namespace injection and `export_classes.info` filtering for cppia.

Status:

- This is the strongest system in the repo.
- The `cpp` path is real and covered by end-to-end tests.
- The `js` path is stale and should not be treated as equivalent support today.

What is good:

- The config object is a step toward a single source of truth.
- Override resolution is explicit in `ScriptResolution`.
- Watcher/compile/reload flow is covered by tests.
- The system already assumes breaking changes are allowed, which is the right posture.

What is weak:

- The cpp loader owns too many responsibilities at once.
- The host context model is ad hoc and mostly `Dynamic`.
- The JS loader is far behind the cpp loader and is effectively a separate design.
- Compiler setup still depends on incidental conventions like `export_classes.filtered.info` living beside script source.

### 2. File Watching and Debounce Utilities

Files:

- `src/hxcore/io/FileWatcher.hx`
- `src/hxcore/scripting/ScriptWatcher.hx`
- `src/hxcore/scripting/ScriptChangeCoalescer.hx`
- `src/hxcore/util/DebouncedQueue.hx`

Responsibilities:

- Polling-based recursive file watching.
- Filtered change detection.
- Debounced/coalesced change delivery.

Status:

- Useful and actively exercised by the scripting tests.
- Generic enough to keep, but currently shaped around scripting.

Notes:

- `FileWatcher` is a polling utility, not an OS-native watcher.
- The layering is reasonable: `FileWatcher` -> `ScriptWatcher` -> loader/runtime behavior.

### 3. App / Stage Runtime Shell

Files:

- `src/hxcore/app/*`
- `src/hxcore/stage/*`

Responsibilities:

- App lifecycle shell.
- Stage update/render loop.
- Camera, overlays, scene stack, root actor handling.

Status:

- Prototype only.
- Not covered by tests.
- Not internally coherent enough to present as production API.

Problems:

- `Stage` hardcodes script loading in the constructor with `script.loadScript("Test", null, null)` which is not library-grade behavior (`src/hxcore/stage/Stage.hx:24`).
- `Stage.update` invokes a script method directly by string and also runs `SystemRegistry`, which makes it an arbitrary composition point rather than a clear abstraction (`src/hxcore/stage/Stage.hx:57`).
- `App.run` ignores `options.frameRate` and instead reads the uninitialized field `frameRate` (`src/hxcore/app/App.hx:79`).
- `AppOptions` defines callbacks like `onUpdate`, `onDispose`, and `onReady`, but `App` does not meaningfully use them (`src/hxcore/app/IApp.hx:7`, `src/hxcore/app/App.hx:28`).

Recommendation:

- Either remove these modules from the public story for now, or rewrite them after the scripting refactor around a much smaller execution model.

### 4. Entity / Actor / ECS

Files:

- `src/hxcore/ecs/*`
- `src/hxcore/actor/*`

Responsibilities:

- `Entity` attaches and updates script hosts.
- `EntityManager` stores entities and updates them.
- `SystemRegistry` stores update callbacks.
- `ActorRegistry` appears to be a thin alternate identity layer.

Status:

- Half-real, half-duplicate.
- `Entity` is useful because it is the main script attachment host in examples.
- The rest is still structural scaffolding.

Problems:

- There are two identity models: `ActorRegistry` and `EntityManager`, with no real reason for both to exist in their current form.
- `ActorRegistry.addComponent` is a stub (`src/hxcore/actor/ActorRegistry.hx:23`).
- `Entity` stores `ctx = {}` but never wires that context into `ScriptHost`; there is even a commented note about it (`src/hxcore/ecs/Entity.hx:61`).
- `Entity.invoke` passes `args` as a single array into a variadic API, which is a smell and likely not what callers expect (`src/hxcore/ecs/Entity.hx:120`).

Recommendation:

- Keep `Entity` only if “script host attached to object” is still the intended gameplay model.
- Otherwise collapse `ActorRegistry`, `EntityManager`, and `SystemRegistry` into one narrower runtime model.

### 5. Events

Files:

- `src/hxcore/events/*`

Responsibilities:

- Small in-process event emitter used by scripts/hosts.

Status:

- Fine as a utility.
- Minimal and easy to reason about.

Recommendation:

- Keep it, but only as a utility. It is not a “system”.

### 6. Logging

Files:

- `src/hxcore/logging/*`

Responsibilities:

- Structured-ish logging with target-specific formatting.

Status:

- Useful utility.
- Independent enough to keep.

Recommendation:

- Keep, but avoid letting log formatting drive runtime architecture.

### 7. Macros and Native Interop

Files:

- `src/hxcore/macros/*`
- `examples/capp/*`

Responsibilities:

- Namespace injection for scripts.
- Export classes filtering.
- C header/extern generation and bridge generation.

Status:

- Mixed maturity.
- `NamespaceInjector` is directly relevant to scripting.
- `HaxeCBridge`, `ExternGenerator`, and related pieces are substantial but mostly orthogonal to the main library story.

Recommendation:

- Split these into:
  - scripting-critical macros
  - optional native interop tooling

That split will make the core easier to understand and maintain.

### 8. Flecs Wrapper Subtree

Files:

- `src/hxcore/flecs/flecs_wrapper/*`

Status:

- This behaves like an embedded standalone project.
- It has its own bindings, tests, native code, and README.

Recommendation:

- Treat it as a separate package or vendor subtree, not part of the same conceptual “core” surface.

## What Is Actually Proven Today

The tested path is heavily concentrated in scripting.

Green tests:

- `haxe hxml/tests.hxml`
- `haxe hxml/tests-cpp.hxml`

What those tests prove:

- Runtime config application works.
- Internal script loading works.
- External cppia override works.
- Hot compile and hot reload work on cpp.
- Source-root watch mode works for dependency changes.
- Failed hot compile preserves the last good compiled script.

What is not proven:

- `app`, `stage`, `actor`, `camera`, `scene`, `ui`.
- The JS scripting path.
- The macro/native bridge area except incidentally.

## Audit Findings

### High Confidence / Keep Investing

1. `ScriptRuntime` + `ScriptConfig` are the right center of gravity for the scripting API.
2. `ScriptResolution` is the right place for explicit override policy.
3. `ScriptWatcher` + `ScriptChangeCoalescer` + `DebouncedQueue` are good reusable building blocks.
4. `ExportClassesInfoFilter` and `NamespaceInjector` solve real cppia-specific needs and should stay near the scripting system.

### Medium Confidence / Needs Refactor

1. `ScriptHost` is viable, but it needs a typed and explicit environment/state handoff model instead of hidden `Dynamic` context (`src/hxcore/scripting/ScriptHost.hx:35`, `src/hxcore/scripting/ScriptHost.hx:87`).
2. `ScriptCompiler` should become a pure compilation service with zero runtime policy embedded in it.
3. `FileWatcher` is good enough for now, but it should become a generic utility with clearer lifecycle and configuration boundaries.

### Low Confidence / Should Be Demoted or Removed

1. `Stage` as currently written.
2. `App` as currently written.
3. `ActorRegistry` as a separate system.
4. ECS as currently presented in `ComponentRegistry` and `SystemRegistry`.
5. The JS loader as a supported equivalent to cpp.

## Scripting Tightening Plan

The right move is not a feature expansion. The right move is to narrow the scripting area around a few strong concepts and push everything else behind them.

### Target Architecture

Keep these public concepts:

1. `ScriptConfig`
2. `ScriptRuntime`
3. `ScriptHost`
4. `ScriptCompiler`
5. `IScriptLoader`

Internally split the current cpp loader into these responsibilities:

1. `ScriptResolver`
   - Chooses internal vs external source.
   - Resolves paths and generated class names.
2. `ScriptCompilerService`
   - Pure compile request in, result out.
   - No watcher logic.
3. `ScriptReloadCoordinator`
   - Owns source watcher and compiled watcher.
   - Converts changes into compile/reload actions.
4. `CppiaScriptLoader`
   - Loads compiled modules and instantiates classes.
   - No watcher setup and no compile invocation.
5. `ScriptCatalog` or `LoadedScriptRegistry`
   - Owns cache entries, active watchers, and loaded metadata.

This is mostly a responsibility split of the current `ScriptLoader.cpp.hx`, not a reinvention.

### Key Simplifications

1. Make `ScriptRuntime` the only owner of loader lifecycle and watcher lifecycle.
2. Make script load decisions entirely data-driven from config and resolution state.
3. Replace hidden host mutation with a typed environment object.
4. Unify “initial load” and “reload” around one lifecycle transition pipeline.
5. Treat JS as either:
   - unsupported for HCR until rebuilt, or
   - a second implementation that must honor the exact same loader contract.

### Concrete Refactor Opportunities

#### A. Collapse Path and Resolution Rules Into One Place

Right now path policy is spread across:

- `ScriptConfig`
- `ScriptRuntime.applyConfig`
- `ScriptLoader.cpp.hx`
- `ScriptCompiler.compileScriptInternal`
- `ScriptWatcher`

This should become a single resolver object that answers:

- source root
- compiled root
- source file path for a class
- compiled file path for a class
- generated fqcn for a class
- `export_classes.filtered.info` location

That removes a large class of drift bugs.

#### B. Replace `Dynamic` Script Context With a Typed Environment

Current state:

- `ScriptHost` mutates `host` and `ctx` into script instances before every call (`src/hxcore/scripting/ScriptHost.hx:87`).
- `Entity` has a `ctx` object but does not wire it through (`src/hxcore/ecs/Entity.hx:61`).

Better shape:

```haxe
typedef ScriptEnvironment = {
	var host:IScriptHost;
	var state:Dynamic;
}
```

Then either:

- pass it to lifecycle/update calls directly, or
- assign one stable environment object once and mutate only `state`.

That makes the “scripts are effectively singleton-ish instances” behavior less hidden.

#### C. Move Watcher Ownership Out of the Loader

Current cpp loader responsibilities include:

- config application
- source resolution
- external loading
- internal fallback
- source watcher creation
- compiled watcher creation
- hot compile invocation
- cache replacement

That is the main source of complexity.

`ScriptLoader.cpp.hx` should become a loading primitive only.

#### D. Formalize Capability Support by Target

The current API implies feature parity, but the implementation does not support that claim.

Current reality:

- cpp: real
- js: stale (`src/hxcore/scripting/ScriptLoader.js.hx:12`)
- generic loader: stub fallback only

Recommendation:

- Add capability flags or documented support levels.
- Fail fast when unsupported combinations are enabled.

#### E. Decide Whether Scripts Are Per-Entity Instances or Shared Code Singletons

The code and comments currently imply:

- code is reloaded centrally
- script instances are created per host
- host mutates environment before every call

That can work, but it should be stated explicitly and encoded cleanly.

You likely want:

- compiled code/module cache shared by runtime
- script instance owned by `ScriptHost`
- entity/game state owned outside the script instance

That is cleaner than the current half-implicit model.

## Suggested Refactor Sequence

### Phase 1: Structural Cleanup Without Behavior Change

1. Move path calculation and fqcn generation into a dedicated resolver.
2. Extract compile invocation from `ScriptLoader.cpp.hx`.
3. Extract watcher setup/coordinator from `ScriptLoader.cpp.hx`.
4. Add explicit target capability checks.
5. Mark JS HCR support as experimental or unsupported until rebuilt.

### Phase 2: Host and State Model Cleanup

1. Introduce a typed script environment object.
2. Decide what script state persists across reload.
3. Remove unused/half-used `ctx` patterns in `Entity`.
4. Make reload lifecycle one code path with explicit old/new handoff semantics.

### Phase 3: Library Surface Reduction

1. Demote or remove `Stage` from default usage.
2. Demote or remove `App` until it is rebuilt.
3. Collapse `ActorRegistry` into `Entity` infrastructure or delete it.
4. Separate `flecs_wrapper` and native bridge areas from the primary library story.

## Recommended Public Story After Refactor

If the goal is a tighter library, the public story should be:

- `hxcore.scripting`: hot-reloadable script runtime for Haxe/cppia, with explicit override and compile workflow.
- `hxcore.util`: small support utilities.
- `hxcore.logging`: logging.
- optional packages:
  - `hxcore.native` or `hxcore.bridge`
  - `hxcore.flecs`
  - future runtime shell if rebuilt

That is much easier to explain than the current “small engine plus scripting plus interop plus ECS plus flecs wrapper” shape.

## Immediate Next Recommendation

If the next step is to tighten scripting while preserving current capabilities, start by refactoring `ScriptLoader.cpp.hx`.

That file is currently the convergence point for:

- policy
- resolution
- watching
- compilation
- external loading
- fallback behavior
- cache updates

It is the highest-leverage place to improve structure without needing to change feature scope first.
