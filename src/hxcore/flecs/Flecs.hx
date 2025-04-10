package hxcore.flecs;

import haxe.Int32;
import cpp.UInt8;
import cpp.Callable;
import haxe.io.UInt32Array;
import cpp.Float32;
import cpp.UInt32;
import cpp.ConstCharStar;
import cpp.Pointer;

typedef Vector2 = {x:Float, y:Float};
typedef Vector3 = {x:Float, y:Float, z:Float};
typedef ObserverCallbackCallable = cpp.Callable<(UInt32, UInt32, UInt32, UInt32) -> Void>;
typedef ObserverCallback = (UInt32, UInt32, UInt32) -> Void;

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

	public static function trampoline(entity:UInt32, comp:UInt32, evt:UInt32, callback_id:UInt32):Void {
		// Log.debug("in trampoline: " + entity + " " + comp + " " + evt + " " + callback_id);
		var cb = cbMap.get(callback_id);
		if (cb != null) {
			cb(entity, comp, evt);
		} else {
			Log.warn("no callback registered for id: " + callback_id);
		}
	}
}

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
  <!--
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper.monolith.c" />
  -->
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper_component.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper_entity.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper_event.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/systems/destination_system.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/systems/move_system.c" />
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
	@:native("flecs_entity_get_velocity") extern static function _flecs_entity_set_velocity(entityIndex:UInt32, x:Float32, y:Float32):Bool;

	@:native("flecs_entity_set_velocity") extern static function _flecs_entity_get_velocity(entityIndex:UInt32, x:cpp.Pointer<Float32>,
		y:cpp.Pointer<Float32>):Bool;

	// Component: Destination
	@:native("flecs_entity_set_destination") extern static function _flecs_entity_set_destination(entityIndex:UInt32, x:Float32, y:Float32, speed:Float32):Bool;

	@:native("flecs_entity_get_destination") extern static function _flecs_entity_get_destination(entityIndex:UInt32, x:cpp.Pointer<Float32>,
		y:cpp.Pointer<Float32>, speed:cpp.Pointer<Float32>):Bool;

	// Observer registration
	@:native("flecs_register_observer") extern static function _flecs_register_observer(componentIds:cpp.Pointer<UInt32>, numComponents:UInt32,
		eventIds:cpp.Pointer<UInt32>, numEvents:UInt32, callback:ObserverCallbackCallable, callbackId:UInt32):Bool;

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

	// Vec2 generic
	public static function setComponentVec2(entity:Int32, componentId:Int32, x:Float, y:Float):Bool
		return _flecs_entity_set_component_vec2(entity, componentId, x, y);

	public static function getComponentVec2(entity:Int32, componentId:Int32):Vector2 {
		var xArr:Array<Float32> = [0.0];
		var yArr:Array<Float32> = [0.0];
		var ok:Bool = _flecs_entity_get_component_vec2(entity, componentId, cpp.Pointer.ofArray(xArr), cpp.Pointer.ofArray(yArr));

		return ok ? {x: xArr[0], y: yArr[0]} : null;
	}

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

		return _flecs_register_observer(Pointer.ofArray(componentsArr), componentsArr.length, Pointer.ofArray(eventsArray),
			eventsArray.length, trampoline, callbackId);
	}
}
