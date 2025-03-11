package core.util;

class TypeUtils {
 
    public static function getInheritanceChain(cls:Class<Dynamic>):Array<Class<Dynamic>> {
        var chain = [];
        while (cls != null) {
            chain.push(cls);
            cls = Type.getSuperClass(cls);
        }
        return chain;
    }

    public static function isDerivedFrom(cls:Class<Dynamic>, base:Class<Dynamic>):Bool {
        #if js
        // I don't know why getInheritanceChain doesn't work on JS, but comparing class names does...
        var inheritanceChain = TypeUtils.getInheritanceChain(cls);
        var ancestorNames:Array<String> = [];
        for (ancestorName in inheritanceChain) {
            ancestorNames.push(Type.getClassName(ancestorName));
        }
        return ancestorNames.contains(Type.getClassName(cls));
        #end

        return TypeUtils.getInheritanceChain(cls).indexOf(base) != -1;
    }

}
