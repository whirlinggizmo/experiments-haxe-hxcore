package hxcore.flecs;

import cpp.Float32;
import cpp.UInt32;
import cpp.UInt64;

typedef SystemCallback = cpp.Callable<cpp.Pointer<UInt64>->UInt32->cpp.Pointer<cpp.Pointer<cpp.Void>>->UInt32->Float32->UInt32->Void>;

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
	// Component management
	@:native("flecs_component_get_id_by_name")
	extern public static function getComponentId(name:String):UInt32;

	@:native("flecs_component_is_tag")
	extern public static function isComponentTag(componentId:UInt32):Bool;

	@:native("flecs_component_print_registry")
	extern public static function printComponentRegistry():Void;

	@:native("flecs_component_create")
	extern public static function createComponent(name:String, size:UInt32):UInt32;

	// Entity inspection

	@:native("flecs_entity_print_components")
	extern public static function printEntityComponents(entityId:UInt32):Void;

	@:native("flecs_entity_has_component")
	extern public static function hasComponent(entityId:UInt32, componentId:UInt32):Bool;

	@:native("flecs_entity_has_component_by_name")
	extern public static function hasComponentByName(entityId:UInt32, name:String):Bool;

	// Entity modification

	@:native("flecs_entity_add_component")
	extern public static function addComponent(entityId:UInt32, componentId:UInt32):Bool;

	@:native("flecs_entity_add_component_by_name")
	extern public static function addComponentByName(entityId:UInt32, name:String):Bool;

	@:native("flecs_entity_remove_component")
	extern public static function removeComponent(entityId:UInt32, componentId:UInt32):Bool;

	@:native("flecs_entity_remove_component_by_name")
	extern public static function removeComponentByName(entityId:UInt32, name:String):Bool;

	@:native("flecs_entity_set_component")
	extern public static function flecs_entity_set_component(entityId:UInt32, componentId:UInt32, componentPtr:cpp.Pointer<cpp.Void>):Bool;

	public static function setComponent(entityId:UInt32, componentId:UInt32, component:Dynamic):Bool {
		return flecs_entity_set_component(entityId, componentId, component);
	}

	@:native("flecs_entity_get_component")
	extern public static function flecs_entity_get_component(entityId:UInt32, componentId:UInt32):cpp.Pointer<cpp.Void>;

	// Returns a copy of the component data (it is a copy of ptr.ref)

	@:generic
	public static function getComponent<T>(entityId:UInt32, componentId:UInt32):T {
		var ptr:cpp.Pointer<T> = cast flecs_entity_get_component(entityId, componentId);

		if (ptr == null) {
			throw 'Component not found for entity $entityId and component $componentId';
		}

		// returns a copy of the component data
		return ptr.ref;
	}

	// Gets a pointer to the actual component data, can be edited directly via ptr.ref

	@:generic
	public static function getComponentPtr<T>(entityId:UInt32, componentId:UInt32):cpp.Pointer<T> {
		return cast flecs_entity_get_component(entityId, componentId);
	}

	@:native("flecs_entity_mark_component")
	extern public static function markComponent(entityId:UInt32, componentId:UInt32):Void;

	// Entity lifecycle

	@:native("flecs_entity_create")
	extern public static function createEntity(name:String):UInt32;

	@:native("flecs_entity_destroy")
	extern public static function destroyEntity(entityId:UInt32):Bool;

	@:native("flecs_entity_get_id")
	extern public static function getEntityId(ecsId:UInt64):UInt32;

	@:native("flecs_register_system")
	extern public static function flecs_register_system(name:String, component_ids:cpp.Pointer<UInt32>, num_components:UInt32, callback:SystemCallback,
		callback_id:UInt32):Bool;

	// Lifecycle

	@:native("flecs_init")
	extern public static function init():Void;

	@:native("flecs_progress")
	extern public static function progress(delta:Float32):Void;

	@:native("flecs_fini")
	extern public static function fini():Void;

	// Version

	@:native("flecs_version")
	extern public static function version():String;

	// observer

	@:native("flecs_register_observer")
	extern static function flecs_register_observer(componentIds:cpp.Pointer<UInt32>, numComponents:UInt32, eventIds:cpp.Pointer<UInt32>, numEvents:UInt32,
		callback:ObserverCallbackCallable, callbackId:UInt32):Bool;

	public static function registerObserver(componentIds:Array<UInt32>, eventIds:Array<UInt32>, callback:ObserverCallbackHandler):Bool {
		if (componentIds == null)
			return false;
		if (componentIds.length == 0)
			return false;
		if (eventIds == null)
			return false;
		if (eventIds.length == 0)
			return false;

		var componentsArr = new Array<UInt32>();
		for (id in componentIds) {
			componentsArr.push(id);
		}

		var eventsArray = new Array<UInt32>();
		for (id in eventIds) {
			eventsArray.push(id);
		}

		// since C wants a static function pointer, we pass it the static trampoline function from CallbackRegistry.
		// the trampoline function will will lookup the actual function (based on the callback_id), and call it.
		final trampoline:ObserverCallbackCallable = cpp.Callable.fromStaticFunction(ObserverCallbackRegistry.trampoline);
		final callbackId = ObserverCallbackRegistry.register(callback);

		return flecs_register_observer(cpp.Pointer.ofArray(componentsArr), componentsArr.length, cpp.Pointer.ofArray(eventsArray), eventsArray.length,
			trampoline, callbackId);
	}
}

typedef ObserverCallbackCallable = cpp.Callable<(entityId:UInt32, componentId:UInt32, eventId:UInt32, componentPtr:cpp.RawPointer<cpp.Void>,
		componentSize:UInt32, callbackId:UInt32) -> Void>;

typedef ObserverCallbackHandler = (entityId:UInt32, componentId:UInt32, eventId:UInt32, component:Dynamic) -> Void;

class ObserverCallbackRegistry {
	static var nextCallbackId:UInt32 = 1; // reserve 0 for invalid id
	static var cbMap:Map<UInt32, ObserverCallbackHandler> = new Map();

	public static function register(cb:ObserverCallbackHandler, ?id:UInt32):UInt32 {
		if (cb == null) {
			Log.warn("No callback function provided to CallbackRegistry.register");
			return 0;
		}

		// generate an id if one isn't provided
		if (id == null) {
			id = nextCallbackId++;
			// nextCallbackId++;
		}

		Log.debug('registering callback ${cb} for id: ${id}');
		if (cbMap.get(id) != null) {
			Log.warn("callback already registered for id: " + id);
			return 0;
		}
		cbMap.set(id, cb);

		Log.debug("registered callback for id: " + id);

		// return the id
		return id;
	}

	public static function trampoline(entityId:UInt32, componentId:UInt32, eventId:UInt32, componentPtr:cpp.RawPointer<cpp.Void>, componentSize:UInt32,
			callbackId:UInt32):Void {
		// Log.debug("in trampoline: " + entityId + " " + componentId + " " + eventId + " " + callbackId);
		var cb:ObserverCallbackHandler = cbMap.get(callbackId);
		if (cb != null) {
			trace("in trampoline: " + entityId + " " + componentId + " " + eventId + " " + callbackId);
			// convert componentPtr to component
			var component:Dynamic = null;
			final positionComponentId = 1;
			final velocityComponentId = 2;

			if (componentId == positionComponentId) {
				// convert componentPtrArray to Vector2
				var vecPtr:cpp.Pointer<Position> = cast componentPtr;
				var vec:Position = vecPtr[0];
				component = {x: vec.x, y: vec.y};
				trace('Position: (${vec.x}, ${vec.y})');
			}

			//cb(eventId, componentId, eventId, component);
		} else {
			Log.warn("no callback registered for id: " + callbackId);
		}
	}
}

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
