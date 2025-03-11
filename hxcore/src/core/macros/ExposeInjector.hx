package core.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

@:keep
class ExposeInjector {
    macro public static function build(): Array<Field> {
        var localClassRef = Context.getLocalClass();
        if (localClassRef == null) return Context.getBuildFields();
        
        var cls = localClassRef.get();
        
        // Check if this class extends Script
        var superClass = cls.superClass;
        var isScriptDerived = false;
        
        while (superClass != null) {
            var superClassName = superClass.t.get().name;
            if (superClassName == "Script") {
                isScriptDerived = true;
                break;
            }
            superClass = superClass.t.get().superClass;
        }
        
        // If it's not a Script-derived class, return fields unchanged
        if (!isScriptDerived) {
            return Context.getBuildFields();
        }
        
        // Check if @:expose metadata already exists
        var hasExpose = false;
        for (meta in cls.meta.get()) {
            if (meta.name == "expose") {
                hasExpose = true;
                break;
            }
        }
        
        // If @:expose is not present, add it
        if (!hasExpose) {
            cls.meta.add("expose", [], cls.pos);
        }
        
        return Context.getBuildFields();
    }
}