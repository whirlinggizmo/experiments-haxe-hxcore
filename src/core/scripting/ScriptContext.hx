package core.scripting;

typedef ScriptContext = Dynamic;

/*
@:forward
abstract ScriptContext(Dynamic) {
    public inline function new() {
        this = {};
    }

    public static inline function create():ScriptContext {
        return new ScriptContext();
    }

    @:arrayAccess
    public inline function arrayGet(key:String):Dynamic {
        return Reflect.field(this, key);
    }

    @:arrayAccess
    public inline function arraySet(key:String, value:Dynamic):Dynamic {
        Reflect.setField(this, key, value);
        return value;
    }

    @:resolve
    public inline function resolve(name:String):Dynamic {
        return Reflect.field(this, name);
    }
}

*/