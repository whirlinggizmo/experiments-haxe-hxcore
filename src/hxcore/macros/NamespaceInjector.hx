package hxcore.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#end

@:keep
class NamespaceInjector {

  // -- Helpers --------------------------------------------------------------

  #if macro
  static inline function fqName(pack:Array<String>, name:String):String {
    return (pack.length == 0 ? name : pack.join(".") + "." + name);
  }

  static inline function injectedFqName(ns:String, pack:Array<String>, name:String):String {
    var base = fqName(pack, name);
    return (ns.length == 0 ? base : ns + "." + base);
  }

  static function isScriptDerived(cls:ClassType, scriptFqcn:String):Bool {
    // Resolve the target Script type once
    var t = try Context.getType(scriptFqcn) catch (_:Dynamic) null;
    if (t == null) return false;
    var target =
      switch (t) {
        case TClassDecl(cd): cd.get();
        default: return false;
      }

    var cur = cls.superClass;
    while (cur != null) {
      var superCls = cur.t.get();
      if (superCls.module == target.module && superCls.name == target.name && superCls.pack.join(".") == target.pack.join(".")) {
        return true;
      }
      cur = superCls.superClass;
    }
    return false;
  }

  static function alreadyHasNative(meta:haxe.macro.Expr.Metadata):Bool {
    for (m in meta) if (m.name == ":native") return true;
    return false;
  }
  #end

  // -- Per-class build macros ----------------------------------------------

  /**
   * @:build(NamespaceInjector.inject("gen"))
   * Always remap to ns.<original.fqcn> for cppia builds (or all builds if you want).
   */
  macro public static function inject(namespace:String, onlyWhenDefine:String = "cppia"):Array<Field> {
    #if macro
    var cRef = Context.getLocalClass();
    if (cRef == null) {
      Context.error("NamespaceInjector.inject can only be used on classes", Context.currentPos());
      return Context.getBuildFields();
    }
    if (onlyWhenDefine != null && onlyWhenDefine != "" && !Context.defined(onlyWhenDefine)) {
      return Context.getBuildFields(); // no-op outside desired build
    }

    var c = cRef.get();
    var newFq = injectedFqName(namespace, c.pack, c.name);
    // Force override: safer for your cppia isolation
    if (!alreadyHasNative(c.meta)) {
      c.meta.add(":native", [macro $v{newFq}], c.pos);
    } else {
      // Replace behavior: remove/replace isn’t exposed, so add only if absent to avoid dup error.
      // If you truly need to override, prefer the global init macro approach instead of per-class build.
    }
    Context.info('NamespaceInjector.inject → ' + newFq, c.pos);
    #end
    return Context.getBuildFields();
  }

  /**
   * Like inject(), but also records the original FQCN as @:originalName metadata.
   */
  macro public static function injectWithTracking(namespace:String, onlyWhenDefine:String = "cppia"):Array<Field> {
    #if macro
    var cRef = Context.getLocalClass();
    if (cRef == null) {
      Context.error("NamespaceInjector.injectWithTracking can only be used on classes", Context.currentPos());
      return Context.getBuildFields();
    }
    if (onlyWhenDefine != null && onlyWhenDefine != "" && !Context.defined(onlyWhenDefine)) {
      return Context.getBuildFields();
    }

    var c = cRef.get();
    var original = fqName(c.pack, c.name);
    var newFq = injectedFqName(namespace, c.pack, c.name);

    if (!alreadyHasNative(c.meta)) c.meta.add(":native", [macro $v{newFq}], c.pos);
    c.meta.add(":originalName", [macro $v{original}], c.pos);

    Context.info('NamespaceInjector.injectWithTracking → ' + original + ' → ' + newFq, c.pos);
    #end
    return Context.getBuildFields();
  }

  // -- Global init macro (preferred for bulk remap) ------------------------

  /**
   * Add to hxml:  --macro hxcore.macros.NamespaceInjector.autoInject("gen","cppia","hxcore.Script")
   * Remaps ALL classes derived from hxcore.Script to gen.<fqcn> (only when -D cppia).
   * Safer than onGenerate; runs during typing.
   */
  macro public static function autoInject(namespace:String, onlyWhenDefine:String = "cppia", scriptBaseFqcn:String = "hxcore.Script"):Void {
    #if macro
    if (onlyWhenDefine != null && onlyWhenDefine != "" && !Context.defined(onlyWhenDefine)) return;

    for (t in Context.getTypes()) {
      switch (t) {
        case TClassDecl(cRef):
          var c = cRef.get();
          if (!isScriptDerived(c, scriptBaseFqcn)) continue;

          var newFq = injectedFqName(namespace, c.pack, c.name);
          if (!alreadyHasNative(c.meta)) {
            c.meta.add(":native", [macro $v{newFq}], c.pos);
            Context.info('autoInject → ' + newFq, c.pos);
          }
        default:
      }
    }
    #end
  }

  // -- Runtime utilities (unchanged) ---------------------------------------

  public static function getOriginalClassName(className:String, injectedNamespace:String):String {
    var parts = className.split(".");
    if (parts.length > 0 && parts[0] == injectedNamespace) {
      parts.shift();
      return parts.join(".");
    }
    return className;
  }

  public static function getInjectedClassName(originalClassName:String, injectedNamespace:String):String {
    return injectedNamespace.length == 0 ? originalClassName : injectedNamespace + "." + originalClassName;
  }
}
