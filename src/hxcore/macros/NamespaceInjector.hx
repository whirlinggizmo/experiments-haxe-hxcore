package hxcore.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * NamespaceInjector macro that injects a namespace prefix into script classes
 * using :native metadata to avoid conflicts with built-in classes.
 * 
 * This macro allows runtime-compiled scripts to coexist with statically compiled
 * versions by giving them different package namespaces.
 * 
 * Usage: Add @:build(NamespaceInjector.inject("gen")) to script classes
 * or use it programmatically during compilation.
 */
@:keep
class NamespaceInjector {
    
    /**
     * Macro that injects a namespace prefix into the current class.
     * This changes the effective package name of the class at compile time.
     * 
     * @param namespace The namespace prefix to inject (e.g., "gen")
     * @return The modified class fields
     */
    macro public static function inject(namespace:String):Array<Field> {
        var localClassRef = Context.getLocalClass();
        if (localClassRef == null) {
            Context.error("NamespaceInjector can only be used on classes", Context.currentPos());
            return Context.getBuildFields();
        }
        
        var cls = localClassRef.get();
        
        // Get the current package
        var currentPackage = cls.pack;
        
        // Create the new package with the injected namespace
        var newPackage = [namespace].concat(currentPackage);
        
        // Set the new package using :native metadata
        // This tells Haxe to use the new package name for this class
        cls.meta.add(":native", [macro $v{newPackage.join(".")}], cls.pos);
        
        Context.info('Injected namespace "$namespace" into class ${cls.name}. New package: ${newPackage.join(".")}', cls.pos);
        
        return Context.getBuildFields();
    }
    
    /**
     * Macro that conditionally injects a namespace based on compilation context.
     * This is useful for distinguishing between runtime-compiled and statically-compiled versions.
     * 
     * @param namespace The namespace prefix to inject
     * @param condition Optional condition for when to inject the namespace
     * @return The modified class fields
     */
    macro public static function injectConditional(namespace:String, ?condition:Expr):Array<Field> {
        var localClassRef = Context.getLocalClass();
        if (localClassRef == null) {
            Context.error("NamespaceInjector can only be used on classes", Context.currentPos());
            return Context.getBuildFields();
        }
        
        var cls = localClassRef.get();
        
        // Check if we should inject the namespace
        var shouldInject = true;
        
        if (condition != null) {
            // Evaluate the condition at compile time
            try {
                var conditionValue = Context.eval(condition);
                shouldInject = conditionValue;
            } catch (e:Dynamic) {
                Context.warning('Could not evaluate condition: $e', condition.pos);
                shouldInject = true; // Default to injecting
            }
        }
        
        if (shouldInject) {
            // Get the current package
            var currentPackage = cls.pack;
            
            // Create the new package with the injected namespace
            var newPackage = [namespace].concat(currentPackage);
            
            // Set the new package using :native metadata
            cls.meta.add(":native", [macro $v{newPackage.join(".")}], cls.pos);
            
            Context.info('Conditionally injected namespace "$namespace" into class ${cls.name}. New package: ${newPackage.join(".")}', cls.pos);
        } else {
            Context.info('Skipped namespace injection for class ${cls.name} due to condition', cls.pos);
        }
        
        return Context.getBuildFields();
    }
    
    /**
     * Macro that injects namespace and also adds metadata to track the original class name.
     * This is useful for runtime resolution where you need to know both the original and generated names.
     * 
     * @param namespace The namespace prefix to inject
     * @return The modified class fields
     */
    macro public static function injectWithTracking(namespace:String):Array<Field> {
        var localClassRef = Context.getLocalClass();
        if (localClassRef == null) {
            Context.error("NamespaceInjector can only be used on classes", Context.currentPos());
            return Context.getBuildFields();
        }
        
        var cls = localClassRef.get();
        
        // Store the original package name for later reference
        var originalPackage = cls.pack.length > 0 ? cls.pack.join(".") : "";
        var originalFullName = originalPackage.length > 0 ? '$originalPackage.${cls.name}' : cls.name;
        
        // Get the current package
        var currentPackage = cls.pack;
        
        // Create the new package with the injected namespace
        var newPackage = [namespace].concat(currentPackage);
        var newFullName = newPackage.join(".") + "." + cls.name;
        
        // Set the new package using :native metadata
        cls.meta.add(":native", [macro $v{newFullName}], cls.pos);
        
        // Add metadata to track the original name
        cls.meta.add(":originalName", [macro $v{originalFullName}], cls.pos);
        
        Context.info('Injected namespace "$namespace" into class ${cls.name}. Original: $originalFullName, New: $newFullName', cls.pos);
        
        return Context.getBuildFields();
    }
    
    /**
     * Utility function to get the original class name from a class with injected namespace.
     * This can be used at runtime to resolve the original class name.
     * 
     * @param className The current class name (with injected namespace)
     * @return The original class name (without injected namespace)
     */
    public static function getOriginalClassName(className:String, injectedNamespace:String):String {
        // Remove the injected namespace prefix
        var parts = className.split(".");
        if (parts.length > 0 && parts[0] == injectedNamespace) {
            parts.shift(); // Remove the first part (the injected namespace)
            return parts.join(".");
        }
        return className; // Return as-is if namespace not found
    }
    
    /**
     * Utility function to get the injected class name from an original class name.
     * This can be used at runtime to resolve the injected class name.
     * 
     * @param originalClassName The original class name
     * @param injectedNamespace The namespace to inject
     * @return The class name with injected namespace
     */
    public static function getInjectedClassName(originalClassName:String, injectedNamespace:String):String {
        if (originalClassName.length == 0) {
            return injectedNamespace;
        }
        return injectedNamespace + "." + originalClassName;
    }
    
    /**
     * Global macro that automatically applies namespace injection to Script-derived classes.
     * This macro runs on all classes and only injects namespace for classes that extend Script.
     * 
     * Usage: Add --macro hxcore.macros.NamespaceInjector.autoInject("gen") to your hxml
     */
    macro public static function autoInject(namespace:String):Void {
        Context.onGenerate((types:Array<Type>) -> {
            for (type in types) {
                switch (type) {
                    case TClassDecl(classRef):
                        var cls = classRef.get();
                        
                        // Check if this class extends Script
                        if (isScriptDerived(cls)) {
                            // Get the current package
                            var currentPackage = cls.pack;
                            
                            // Create the new package with the injected namespace
                            var newPackage = [namespace].concat(currentPackage);
                            var newFullName = newPackage.join(".") + "." + cls.name;
                            
                            // Set the new package using :native metadata
                            cls.meta.add(":native", [macro $v{newFullName}], cls.pos);
                            
                            Context.info('Auto-injected namespace "$namespace" into Script class ${cls.name}. New package: $newFullName', cls.pos);
                        }
                    default:
                        // Ignore other types
                }
            }
        });
    }
    
    /**
     * Helper function to check if a class extends Script (directly or indirectly)
     */
    private static function isScriptDerived(cls:ClassType):Bool {
        var superClass = cls.superClass;
        
        while (superClass != null) {
            var superClassName = superClass.t.get().name;
            if (superClassName == "Script") {
                return true;
            }
            superClass = superClass.t.get().superClass;
        }
        
        return false;
    }
}
