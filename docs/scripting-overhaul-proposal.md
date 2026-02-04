# Scripting Overhaul Proposal

## Goals
1. Make cppia and JS HCR reliable, with predictable override rules.
2. Keep a single script source base for dev and release builds.
3. Prefer `hxcore` utilities and extensions over app-specific code.

## High-Level Design
1. Split responsibilities into: source discovery, compilation, loading, runtime host, and update transport.
2. Make external override behavior explicit and configurable.
3. Make output paths and namespace rules single-source-of-truth.

## Modules
1. `hxcore.scripting.ScriptRuntime`
   - Owns resolution order, caching, reload policies, and lifecycle transitions.
   - Exposes: `load`, `reload`, `unload`, `attach`, `detach`, `invalidate`.
2. `hxcore.scripting.ScriptCompiler`
   - Keep, but refactor to be a pure compilation service.
   - Output path is passed in and used consistently.
3. `hxcore.scripting.ScriptLoader`
   - Target-specific loader only. No watcher logic.
   - CPP: load cppia module and resolve generated class.
   - JS: dynamic import and instantiate.
4. `hxcore.scripting.ScriptWatcher`
   - Wraps `hxcore.io.FileWatcher` and handles debounce, coalescing, and change classification.
   - Emits events: `SourceChanged`, `CompiledChanged`.
5. `hxcore.scripting.ScriptNamespace`
   - Centralizes generated namespace and class remapping logic.
   - Uses `hxcore.macros.NamespaceInjector`.
6. `hxcore.scripting.ScriptExportFilter`
   - Centralizes logic for filtering `export_classes.info`.
   - Ensures required base classes are included in cppia output.
7. `hxcore.scripting.ScriptUpdateTransport` (optional)
   - Abstract transport for no-file-IO environments.
   - Implementations: `FileWatcherTransport`, `HttpFetchTransport`.

## Data Flow
1. `ScriptRuntime.load(name)`
2. `ScriptLoader` resolves external first if enabled.
3. If external missing or fails, fall back to internal.
4. If watchers enabled:
   - Source change -> `ScriptCompiler` -> compiled output updated.
   - Compiled change -> `ScriptRuntime.reload(name)`.

## Key Decisions
1. Single config object used everywhere:
   - `scriptSourceRoot`, `scriptOutputRoot`, `generatedNamespace`, `overrideMode`.
2. No hidden output paths. The compiler must write to configured output root.
3. Hot reload updates the cache, not just host instance.
4. `export_classes.info` filtering is explicit and testable.

## Override Rules
1. `overrideMode = ExternalFirst` default for dev.
2. `overrideMode = InternalOnly` for release builds by default.
3. `overrideMode = ExternalOnly` optional for mod-only workflows.

## No-File-IO Environments
1. Define a transport interface that can fetch or receive compiled scripts.
2. For browser JS, prefer HTTP fetch or websocket push of compiled scripts.
3. For wasm, prototype whether dynamic loading is feasible.

## Compatibility
1. Backward compatibility not required.
2. Public APIs can change for clarity and reliability.

## Risks
1. Namespace injection and `export_classes.info` filtering break overrides.
2. Watcher debounce too aggressive or too weak.
3. JS target HMR differs from cppia behavior.

## Test Strategy
1. Unit tests for namespace mapping, export filtering, watcher matching.
2. Integration tests for hot compile and hot reload.
3. Regression tests on `examples/scripttest`.

## Next Step
1. Draft a concrete API sketch and config object.
2. Or start with `ScriptRuntime` skeleton and refactor existing code into it.
