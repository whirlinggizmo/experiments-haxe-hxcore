package hxcore.flecs;

import cpp.RawPointer;
import haxe.Int32;
import cpp.Callable;
import cpp.Float32;
import cpp.UInt32;
import cpp.Pointer;

// Known components
// see flecs_wrapper_components.h

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

//

typedef ObserverCallbackCallable = cpp.Callable<(entityId:UInt32, componentId:UInt32, eventId:UInt32, componentPtr:cpp.RawPointer<cpp.Void>,
		componentSize:UInt32, callbackId:UInt32) -> Void>;

typedef ObserverCallback = (entityId:UInt32, componentId:UInt32, eventId:UInt32, component:Dynamic) -> Void;

/*
typedef SystemCallbackCallable = cpp.Callable<(entityId:UInt32, componentPtrPtr:cpp.RawPointer<cpp.RawPointer<cpp.Void>>, numComponents:UInt32,
		callbackId:UInt32) -> Void>;

typedef SystemCallback = (entityId:UInt32, components:Array<Dynamic>, numComponents:UInt32) -> Void;
*/

class ObserverCallbackRegistry {
	static var nextCallbackId:Int32 = 1; // reserve 0 for invalid id
	static var cbMap:Map<Int32, ObserverCallback> = new Map();

	public static function register(cb:ObserverCallback, ?id:UInt32):Int32 {
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
		var cb = cbMap.get(callbackId);
		if (cb != null) {
			trace("in trampoline: " + entityId + " " + componentId + " " + eventId + " " + callbackId);
			// convert componentPtr to component
			var component:Dynamic = null;
			final positionComponentId = 1;
			final velocityComponentId = 2;

			if (componentId == positionComponentId) {
				// convert componentPtrArray to Vector2
				var vecPtr:cpp.RawPointer<Position> = cast componentPtr;
				var vec:Position = vecPtr[0];
				component = {x: vec.x, y: vec.y};
				trace('Position: (${vec.x}, ${vec.y})');
			}

			cb(eventId, componentId, eventId, component);
		} else {
			Log.warn("no callback registered for id: " + callbackId);
		}
	}
}

/*
class SystemCallbackRegistry {
	static var nextCallbackId:Int = 1;
	static var cbMap:Map<Int, SystemCallback> = new Map();

	public static function register(cb:SystemCallback):Int {
		var id = nextCallbackId++;
		cbMap.set(id, cb);
		return id;
	}

	public static function trampoline(entityId:UInt32, componentPtrPtr:cpp.RawPointer<cpp.RawPointer<cpp.Void>>, numComponents:UInt32, callbackId:UInt32):Void {
		var cb = cbMap.get(callbackId);
		if (cb == null) {
			Log.warn("no callback registered for id: " + callbackId);
			return;
		}

		// convert componentPtrPtr to array of components

		var components = new Array<Dynamic>();
		for (i in 0...numComponents) {
			// This is hard coded right now for testing the system.
			// It assumes that the components are all Vector2
			// TODO: Fix this to be more generic
			var vecPtr:cpp.RawPointer<Position> = cast componentPtrPtr[i];
			var vec:Position = vecPtr[0];
			components.push({x: vec.x, y: vec.y});
		}
		cb(entityId, components, numComponents);
	}
}
*/

/* 
	// Working buildXml for linking a static lib!
	@:buildXml('
	<files id="haxe">
	  <echo value="Compiling Flecs (wrapper)..." />
	  <compilerflag value="-I../../lib/flecs_wrapper/include"/>
	</files>
	<target id="haxe" tool="linker">
	  <section id="haxe" unless="static_link">
	<echo value="Linking Flecs (wrapper)..." />
	<lib name="-L../../lib/flecs_wrapper/lib"/>
	<lib name="-static"/>
	<lib name="-lflecs_wrapper"/>
	<lib name="--verbose"/>
	  </section>
	</target>
	')
 */
// Working buildXml for building from the sources

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
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/systems/trampoline_system.c" />
  -->
</files>
')
@:headerInclude('flecs_wrapper.h')
@:keep
@:expose
class Flecs {
	// Version
	@:native("flecs_version") extern static function _flecs_version():String;

	// Lifecycle
	@:native("flecs_init") extern static function _flecs_init():Void;

	@:native("flecs_fini") extern static function _flecs_fini():Void;

	@:native("flecs_progress") extern static function _flecs_progress(delta:Float32):Void;

	// Entity management
	@:native("flecs_entity_create") extern static function _flecs_entity_create(name:String):UInt32;

	@:native("flecs_entity_destroy") extern static function _flecs_entity_destroy(id:UInt32):Bool;

	// Component lookup
	@:native("flecs_component_get_id_by_name") extern static function _flecs_component_get_id_by_name(name:String):Int32;

	@:native("flecs_component_is_mark_changed_by_name") extern static function _flecs_component_is_mark_changed_by_name(entityIndex:UInt32, name:String):Bool;

	@:native("flecs_component_is_marked_changed") extern static function _flecs_component_is_marked_changed(entityIndex:UInt32, componentId:UInt32):Bool;

	@:native("flecs_component_is_tag") extern static function _flecs_component_is_tag(componentId:UInt32):Bool;

	@:native("flecs_component_print_registry") extern static function _flecs_component_print_registry():Void;

	// Component management (entity)
	@:native("flecs_entity_add_component") extern static function _flecs_entity_add_component(entityIndex:UInt32, componentId:UInt32):Bool;

	@:native("flecs_entity_add_component_by_name") extern static function _flecs_entity_add_component_by_name(entityIndex:UInt32, name:String):Bool;

	@:native("flecs_entity_remove_component") extern static function _flecs_entity_remove_component(entityIndex:UInt32, componentId:UInt32):Bool;

	@:native("flecs_entity_remove_component_by_name") extern static function _flecs_entity_remove_component_by_name(entityIndex:UInt32, name:String):Bool;

	@:native("flecs_entity_has_component") extern static function _flecs_entity_has_component(entityId:UInt32, componentId:UInt32):Bool;

	@:native("flecs_entity_has_component_by_name") extern static function _flecs_entity_has_component_by_name(entityIndex:UInt32, name:String):Bool;

	@:native("flecs_entity_print_components") extern static function _flecs_entity_print_components(entityIndex:UInt32):Void;

	// TODO:  Add component registrations
	@:native("flecs_register_component") extern static function _flecs_register_component(name:String, size:UInt32):UInt32;

	@:native("flecs_entity_set_component_data") extern static function _flecs_entity_set_component_data(entityIndex:UInt32, componentId:UInt32,
		componentDataPtr:Pointer<cpp.Void>):Bool;

	@:native("flecs_entity_get_component_data") extern static function _flecs_entity_get_component_data(entityIndex:UInt32,
		componentId:UInt32):Pointer<cpp.Void>;

	/*
	// Component: Vec2 generic
	@:native("flecs_entity_set_component_vec2") extern static function _flecs_entity_set_component_vec2(entityIndex:UInt32, componentId:UInt32, x:Float32,
		y:Float32):Bool;

	@:native("flecs_entity_get_component_vec2") extern static function _flecs_entity_get_component_vec2(entityIndex:UInt32, componentId:UInt32,
		x:cpp.Pointer<Float32>, y:cpp.Pointer<Float32>):Bool;

	// Component: Position
	@:native("flecs_entity_set_position") extern static function _flecs_entity_set_position(entityIndex:UInt32, x:Float32, y:Float32):Bool;

	@:native("flecs_entity_get_position") extern static function _flecs_entity_get_position(entityIndex:UInt32, x:cpp.Pointer<Float32>,
		y:cpp.Pointer<Float32>):Bool;

	// Component: Velocity
	@:native("flecs_entity_set_velocity") extern static function _flecs_entity_set_velocity(entityIndex:UInt32, x:Float32, y:Float32):Bool;

	@:native("flecs_entity_get_velocity") extern static function _flecs_entity_get_velocity(entityIndex:UInt32, x:cpp.Pointer<Float32>,
		y:cpp.Pointer<Float32>):Bool;

	// Component: Destination
	@:native("flecs_entity_set_destination") extern static function _flecs_entity_set_destination(entityIndex:UInt32, x:Float32, y:Float32, speed:Float32):Bool;

	@:native("flecs_entity_get_destination") extern static function _flecs_entity_get_destination(entityIndex:UInt32, x:cpp.Pointer<Float32>,
		y:cpp.Pointer<Float32>, speed:cpp.Pointer<Float32>):Bool;
	*/
	
	// Observer registration
	@:native("flecs_register_observer") extern static function _flecs_register_observer(componentIds:cpp.Pointer<UInt32>, numComponents:UInt32,
		eventIds:cpp.Pointer<UInt32>, numEvents:UInt32, callback:ObserverCallbackCallable, callbackId:UInt32):Bool;

	// System registration
	/*
	@:native("flecs_register_system") extern static function _flecs_register_system(name:String, components:cpp.Pointer<UInt32>, numComponents:UInt32,
		callback:SystemCallbackCallable, callbackId:UInt32):Bool;
	*/

	// Public-friendly API
	// see flecs wrapper
	static public final EcsUnknown:UInt32 = 0;
	static public final EcsOnAdd:UInt32 = 1;
	static public final EcsOnRemove:UInt32 = 2;
	static public final EcsOnSet:UInt32 = 3;
	static public final EcsOnDelete:UInt32 = 4;
	static public final EcsOnDeleteTarget:UInt32 = 5;
	static public final EcsOnTableCreate:UInt32 = 6;
	static public final EcsOnTableDelete:UInt32 = 7;

	public static function init():Void
		return _flecs_init();

	public static function fini():Void
		return _flecs_fini();

	public static function progress(delta:Float = 0):Void
		return _flecs_progress(delta);

	public static function version():String
		return _flecs_version();

	public static function createEntity(name:String):UInt
		return _flecs_entity_create(name);

	public static function destroyEntity(id:Int32):Bool
		return _flecs_entity_destroy(id);

	public static function printComponentRegistry():Void
		return _flecs_component_print_registry();

	public static function printEntityComponents(id:Int32):Void
		return _flecs_entity_print_components(id);

	public static function getComponentId(name:String):Int
		return _flecs_component_get_id_by_name(name);

	public static function isComponentTag(id:Int32):Bool
		return _flecs_component_is_tag(id);

	public static function addComponentByName(entity:Int32, name:String):Bool
		return _flecs_entity_add_component_by_name(entity, name);

	public static function hasComponentByName(entity:Int32, name:String):Bool
		return _flecs_entity_has_component_by_name(entity, name);

	// Entity component operations (by ID)
	public static function addComponent(entity:Int32, componentId:Int32):Bool
		return _flecs_entity_add_component(entity, componentId);

	public static function removeComponent(entity:Int32, componentId:Int32):Bool
		return _flecs_entity_remove_component(entity, componentId);

	public static function hasComponent(entity:Int32, componentId:UInt):Bool
		return _flecs_entity_has_component(entity, componentId);

	// Entity component operations (by name)
	public static function removeComponentByName(entity:Int32, name:String):Bool
		return _flecs_entity_remove_component_by_name(entity, name);

	// Change-marking helpers
	public static function isComponentMarkedChanged(entity:Int32, componentId:Int32):Bool
		return _flecs_component_is_marked_changed(entity, componentId);

	public static function isComponentMarkedChangedByName(entity:Int32, name:String):Bool
		return _flecs_component_is_mark_changed_by_name(entity, name);

	// Component data getter/setter
	public static function setComponentData(entity:Int32, componentId:Int32, component:Dynamic):Bool
		return _flecs_entity_set_component_data(entity, componentId, component);

	public static function getComponentData(entity:Int32, componentId:Int32):Dynamic
		return _flecs_entity_get_component_data(entity, componentId);
	
	/*
	// Vector2 generic
	public static function setComponentDataVector2(entity:Int32, componentId:Int32, x:Float, y:Float):Bool {
		var vec2:Vector2 = {x: x, y: y};
		return _flecs_entity_set_component_data(entity, componentId, vec2);
	}

	public static function getComponentDataVector2(entity:Int32, componentId:Int32):Vector2 {
		var vec2:Vector2 = {x: 0.0, y: 0.0};
		var data = _flecs_entity_get_component_data(entity, componentId);

		return data ? cast(data, Vector2) : null;
	}
	*/

	/*
	// Position
	public static function setPosition(entity:Int32, x:Float, y:Float):Bool
		return _flecs_entity_set_position(entity, x, y);

	public static function getPosition(entity:Int32):Vector2 {
		var xArr:Array<Float32> = [0.0];
		var yArr:Array<Float32> = [0.0];
		var ok:Bool = _flecs_entity_get_position(entity, cpp.Pointer.ofArray(xArr), cpp.Pointer.ofArray(yArr));

		return ok ? {x: xArr[0], y: yArr[0]} : null;
	}

	// Velocity
	public static function setVelocity(entity:Int32, x:Float, y:Float):Bool
		return _flecs_entity_set_velocity(entity, x, y);

	public static function getVelocity(entity:Int32):Vector2 {
		var xArr:Array<Float32> = [0.0];
		var yArr:Array<Float32> = [0.0];
		var ok:Bool = _flecs_entity_get_velocity(entity, cpp.Pointer.ofArray(xArr), cpp.Pointer.ofArray(yArr));

		return ok ? {x: xArr[0], y: yArr[0]} : null;
	}

	// Destination
	public static function setDestination(entity:Int32, x:Float, y:Float, speed:Float):Bool
		return _flecs_entity_set_destination(entity, x, y, speed);

	public static function getDestination(entity:Int32):{x:Float, y:Float, speed:Float} {
		var xArr:Array<Float32> = [0.0];
		var yArr:Array<Float32> = [0.0];
		var speedArr:Array<Float32> = [0.0];
		var ok:Bool = _flecs_entity_get_destination(entity, cpp.Pointer.ofArray(xArr), cpp.Pointer.ofArray(yArr), cpp.Pointer.ofArray(speedArr));

		return ok ? {x: xArr[0], y: yArr[0], speed: speedArr[0]} : null;
	}
	*/

	// Observer
	public static function registerObserver(componentIds:Array<Int32>, eventIds:Array<Int32>, callback:ObserverCallback):Bool {
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
		final trampoline = cpp.Callable.fromStaticFunction(ObserverCallbackRegistry.trampoline);
		final callbackId = ObserverCallbackRegistry.register(callback);

		return _flecs_register_observer(Pointer.ofArray(componentsArr), componentsArr.length, Pointer.ofArray(eventsArray), eventsArray.length, trampoline,
			callbackId);
	}

	// System
	/*
	public static function registerSystem(name:String, cb:SystemCallback, componentIds:Array<Int>):Bool {
		var callbackId = SystemCallbackRegistry.register(cb);
		var numComponents = componentIds.length;
		var arr = new Array<cpp.UInt32>();
		for (i in 0...componentIds.length)
			arr.push(componentIds[i]);
		var ptr = cpp.Pointer.arrayElem(arr, 0);
		var trampoline = cpp.Callable.fromStaticFunction(SystemCallbackRegistry.trampoline);
		return _flecs_register_system(name, ptr, numComponents, trampoline, callbackId);
	}
	*/
}
