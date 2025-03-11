package core.scripting;

//typedef ScriptContext = Dynamic;


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

/*
@:forward
abstract ScriptContext(ScriptContextImpl) {
    public inline function new() {
        this = new ScriptContextImpl();
    }

    public static inline function create():ScriptContext {
        return new ScriptContext();
    }

    @:arrayAccess
    public inline function arrayGet(key:String):Dynamic {
        return this.get(key);
    }

    @:arrayAccess
    public inline function arraySet(key:String, value:Dynamic):Dynamic {
        return this.set(key, value);
    }

    @:resolve
    public inline function resolve(name:String):Dynamic {
        return this.get(name);
    }
}

@:structInit
class ScriptContextImpl {
    private var kvMap:Map<String, Dynamic> = new Map();

    public function new() {}

    public inline function get(key:String):Dynamic {
        return this.kvMap.get(key);
    }

    public inline function set(key:String, value:Dynamic):Dynamic {
        this.kvMap.set(key, value);
        return value;
    }

    public function remove(key:String):Void {
        this.kvMap.remove(key);
    }

    public function exists(key:String):Bool {
        return this.kvMap.exists(key);
    }

    public function keys():Iterator<String> {
        return this.kvMap.keys();
    }
}
*/