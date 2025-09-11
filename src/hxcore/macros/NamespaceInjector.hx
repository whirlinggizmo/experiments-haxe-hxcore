package hxcore.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

#end

@:keep
class NamespaceInjector {

  // ---------- Helpers ----------
  #if macro
  static inline function fqcn(pack:Array<String>, name:String):String {
    return pack.length == 0 ? name : pack.join(".") + "." + name;
  }

  static inline function injectedFqcn(ns:String, pack:Array<String>, name:String):String {
    var base = fqcn(pack, name);
    return ns == "" ? base : ns + "." + base;
  }

  static inline function classFqcn(c:ClassType):String {
    return fqcn(c.pack, c.name);
  }

  static function isScriptDerived(cls:ClassType, scriptBaseFqcn:String):Bool {
    var cur = cls.superClass;
    while (cur != null) {
      var sup = cur.t.get();
      if (classFqcn(sup) == scriptBaseFqcn) return true;
      cur = sup.superClass;
    }
    return false;
  }

  static function alreadyHasNative(meta:haxe.macro.MetaAccess):Bool {
    for (m in meta.get()) if (m.name == ":native") return true;
    return false;
  }
  #end

  // ---------- Per-class build macros ----------
  /**
   * @:build(NamespaceInjector.inject("gen", "cppia"))
   * Adds @:native("gen.<fqcn>") when -D cppia is defined.
   */
  macro public static function inject(namespace:String, onlyWhenDefine:String = "cppia"):Array<Field> {
    #if macro
    var cRef = Context.getLocalClass();
    if (cRef == null) {
      Context.error("NamespaceInjector.inject must be used on a class", Context.currentPos());
      return Context.getBuildFields();
    }
    if (onlyWhenDefine != null && onlyWhenDefine != "" && !Context.defined(onlyWhenDefine)) {
      return Context.getBuildFields();
    }

    var c = cRef.get();
    var newName = injectedFqcn(namespace, c.pack, c.name);

    if (!alreadyHasNative(c.meta)) c.meta.add(":native", [macro $v{newName}], c.pos);
    Context.info('inject → ' + newName, c.pos);
    #end
    return Context.getBuildFields();
  }

  /**
   * @:build(NamespaceInjector.injectWithTracking("gen", "cppia"))
   * Also writes @:originalName("<fqcn>") for debugging.
   */
  macro public static function injectWithTracking(namespace:String, onlyWhenDefine:String = "cppia"):Array<Field> {
    #if macro
    var cRef = Context.getLocalClass();
    if (cRef == null) {
      Context.error("NamespaceInjector.injectWithTracking must be used on a class", Context.currentPos());
      return Context.getBuildFields();
    }
    if (onlyWhenDefine != null && onlyWhenDefine != "" && !Context.defined(onlyWhenDefine)) {
      return Context.getBuildFields();
    }

    var c = cRef.get();
    var original = fqcn(c.pack, c.name);
    var newName  = injectedFqcn(namespace, c.pack, c.name);

    if (!alreadyHasNative(c.meta)) c.meta.add(":native", [macro $v{newName}], c.pos);
    c.meta.add(":originalName", [macro $v{original}], c.pos);

    Context.info('injectWithTracking → ' + original + ' → ' + newName, c.pos);
    #end
    return Context.getBuildFields();
  }

  // ---------- Global init macro ----------
  /**
   * HXML: --macro hxcore.macros.NamespaceInjector.autoInject("gen","cppia","hxcore.Script")
   * Remaps ALL classes derived from hxcore.Script to gen.<fqcn> (only when -D cppia).
   */
  macro public static function autoInject(namespace:String, onlyWhenDefine:String = "cppia", scriptBaseFqcn:String = "hxcore.Script"):Void {
    #if macro
    if (onlyWhenDefine != null && onlyWhenDefine != "" && !Context.defined(onlyWhenDefine)) return;

    // Run after typing; types: Array<ModuleType>
    Context.onAfterTyping(function(types:Array<ModuleType>) {
      for (t in types) {
        switch (t) {
          case TClassDecl(cRef):
            var c = cRef.get();
            if (!isScriptDerived(c, scriptBaseFqcn)) continue;

            var newName = injectedFqcn(namespace, c.pack, c.name);
            if (!alreadyHasNative(c.meta)) {
              c.meta.add(":native", [macro $v{newName}], c.pos);
              Context.info('autoInject → ' + newName, c.pos);
            }
          default:
        }
      }
    });
    #end
  }

  // ---------- Runtime helpers (unchanged) ----------
  public static function getOriginalClassName(className:String, injectedNamespace:String):String {
    var parts = className.split(".");
    if (parts.length > 0 && parts[0] == injectedNamespace) { parts.shift(); return parts.join("."); }
    return className;
  }

  public static function getInjectedClassName(originalClassName:String, injectedNamespace:String):String {
    return injectedNamespace.length == 0 ? originalClassName : injectedNamespace + "." + originalClassName;
  }

  /** Force-add @:native(nativeFqcn) to a class by name. */
  public static macro function setNative(fqcn:String, nativeFqcn:String):Void {
    var t = Context.getType(fqcn);
    switch (t) {
      case TInst(cRef, _):
        var c = cRef.get();
        c.meta.add(":native", [macro $v{nativeFqcn}], c.pos);
      default:
        Context.error('$fqcn is not a class', Context.currentPos());
    }
    return;
  }
}
