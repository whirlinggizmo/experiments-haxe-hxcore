package hxcore.flecs;

import cpp.Float32;

@:buildXml('
<echo value="Compiling Flecs (wrapper)..." />
<echo value="hxlib path: ${haxelib:hxcore}" />
<files id="haxe">
  <compilerflag value="-I${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/include"/>
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper_component.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper_components.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper_world.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper_entity.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper_event.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/systems/destination_system.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/systems/move_system.c" />
  <!--
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper_system.c" />
  -->
</files>
')
@:headerInclude('flecs_wrapper.h')
@:keep
@:expose
class Flecs {

   /*
    static function fromVoidPointer(p:cpp.RawPointer<cpp.Void>):Dynamic {
        return untyped __cpp__("Dynamic(static_cast<hx::Object*>(p))");
    }
    
    static function toVoidPointer(o:Dynamic):cpp.RawPointer<cpp.Void> {
        return untyped __cpp__("o.GetPtr()");
    }
        */

    // Component management
    @:native("flecs_component_get_id_by_name")
    extern public static function getComponentId(name:String):UInt;

    @:native("flecs_component_is_tag")
    extern public static function isComponentTag(componentId:UInt):Bool;

    @:native("flecs_component_print_registry")
    extern public static function printComponentRegistry():Void;

    @:native("flecs_component_create")
    extern public static function createComponent(name:String, size:UInt):UInt;

    // Entity inspection
    @:native("flecs_entity_print_components")
    extern public static function printEntityComponents(entityId:UInt):Void;

    @:native("flecs_entity_has_component")
    extern public static function hasComponent(entityId:UInt, componentId:UInt):Bool;

    @:native("flecs_entity_has_component_by_name")
    extern public static function hasComponentByName(entityId:UInt, name:String):Bool;

    // Entity modification
    @:native("flecs_entity_add_component")
    extern public static function addComponent(entityId:UInt, componentId:UInt):Bool;

    @:native("flecs_entity_add_component_by_name")
    extern public static function addComponentByName(entityId:UInt, name:String):Bool;

    @:native("flecs_entity_remove_component")
    extern public static function removeComponent(entityId:UInt, componentId:UInt):Bool;

    @:native("flecs_entity_remove_component_by_name")
    extern public static function removeComponentByName(entityId:UInt, name:String):Bool;

    @:native("flecs_entity_set_component")
    extern public static function _flecs_entity_set_component(entityId:UInt, componentId:UInt, componentPtr:cpp.Pointer<cpp.Void>):Bool;
    public static function setComponent(entityId:UInt, componentId:UInt, component:Dynamic):Bool {
        //var componentPtr = toVoidPointer(component);
        return _flecs_entity_set_component(entityId, componentId, component);
    }

    @:native("flecs_entity_get_component")
    extern public static function _flecs_entity_get_component(entityId:UInt, componentId:UInt):cpp.Pointer<cpp.Void>;
    
    // Returns a copy of the component data (it is a copy of ptr.ref)
    @:generic
    public static function getComponent<T>(entityId:UInt, componentId:UInt):T {
        var ptr:cpp.Pointer<T> = cast Flecs._flecs_entity_get_component(entityId, componentId);

        if (ptr == null) {
            throw 'Component not found for entity $entityId and component $componentId';
        }

        // returns a copy of the component data
        return ptr.ref;
    }

    // Gets a pointer to the actual component data, can be edited directly via ptr.ref
    @:generic
    public static function getComponentPtr<T>(entityId:UInt, componentId:UInt):cpp.Pointer<T> {
        return cast _flecs_entity_get_component(entityId, componentId);
    }    

    @:native("flecs_entity_mark_component")
    extern public static function markComponent(entityId:UInt, componentId:UInt):Void;

    // Entity lifecycle
    @:native("flecs_entity_create")
    extern public static function createEntity(name:String):UInt;

    @:native("flecs_entity_destroy")
    extern public static function destroyEntity(entityId:UInt):Bool;

    @:native("flecs_entity_get_id")
    extern public static function getEntityId(ecsId:haxe.Int64):UInt;

    @:native("flecs_register_observer")
    extern public static function registerObserver(
        component_ids:cpp.Pointer<UInt>,
        num_components:UInt,
        event_ids:cpp.Pointer<UInt>,
        num_events:UInt,
        callback:ObserverCallback,
        callback_id:UInt
    ):Bool;

    @:native("flecs_register_system")
    extern public static function registerSystem(
        name:String,
        component_ids:cpp.Pointer<UInt>,
        num_components:UInt,
        callback:SystemCallback,
        callback_id:UInt
    ):Bool;

    // Lifecycle
    @:native("flecs_init")
    extern public static function init():Void;

    @:native("flecs_progress")
    extern public static function progress(delta:Float):Void;

    @:native("flecs_fini")
    extern public static function fini():Void;

    // Version
    @:native("flecs_version")
    extern public static function version():String;
}

// Callback function signatures (define these on the Haxe side and trampoline if needed)
typedef ObserverCallback = cpp.Callable<cpp.Void->UInt->UInt->cpp.Pointer<cpp.Void>->UInt->UInt->Void>;
typedef SystemCallback = cpp.Callable<cpp.Pointer<haxe.Int64>->UInt->cpp.RawPointer<cpp.Void>->UInt->Float32->UInt->Void>;


// known components
@:structAccess
@:structInit
@:nativeGen
@:native("Position")
class Position {
	public var x:Float32;
	public var y:Float32;
}

@:structAccess
@:structInit
@:nativeGen
@:native("Velocity")
class Velocity {
	public var x:Float32;
	public var y:Float32;
}

@:structAccess
@:structInit
@:nativeGen
@:native("Destination")
class Destination {
	public var x:Float32;
	public var y:Float32;
	public var speed:Float32;
}