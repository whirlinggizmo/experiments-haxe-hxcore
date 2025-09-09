package hxcore.flecs;

import cpp.Float32;
import cpp.UInt32;
import cpp.UInt64;
import cpp.ConstCharStar;
import cpp.Pointer;
import cpp.RawPointer;
import cpp.ConstPointer;
import hxcore.logging.Log;

// Type alias for pointer-sized unsigned integer
#if cpp_64
typedef UIntPtr = cpp.UInt64;
#else
typedef UIntPtr = cpp.UInt32;
#end
// Type alias for pointers to UInt64
typedef UInt64Ptr = cpp.Pointer<UInt64>;

// typedef SystemCallback = cpp.Callable<UInt64Ptr->UInt32->cpp.Pointer<cpp.Pointer<cpp.Void>>->UInt32->Float32->UInt32->Void>;
//typedef SystemCallback = cpp.Callable<(entities:cpp.ConstPointer<UInt64>, numEntities:UInt32, components:cpp.Pointer<cpp.RawPointer<cpp.Void>>,
//		numComponents:UInt32, deltaTime:Float32, callbackId:UInt32) -> Void>;

// typedef ObserverCallback = cpp.Callable<UInt32->UInt32->UInt32->cpp.RawPointer<cpp.Void>->UInt32->UInt32->Void>;
typedef ObserverCallback = cpp.Callable<(entityId:UInt32, componentId:UInt32, eventId:UInt32, componentPtr:cpp.RawPointer<cpp.Void>, componentSize:UInt32,
		callbackId:UInt32) -> Void>;

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
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/flecs_wrapper_system.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/systems/destination_system.c" />
  <file name="${haxelib:hxcore}/src/hxcore/flecs/flecs_wrapper/src/systems/move_system.c" />
</files>
')
@:headerInclude('flecs_wrapper.h')
@:keep
@:expose
class Flecs {

	// event types
	public static final EcsUnknownEvent:UInt32 = 0;
	public static final EcsOnAdd:UInt32 = 1;
	public static final EcsOnRemove:UInt32 = 2;
	public static final EcsOnSet:UInt32 = 3;
	public static final EcsOnDelete:UInt32 = 4;
	public static final EcsOnDeleteTarget:UInt32 = 5;
	public static final EcsOnTableCreate:UInt32 = 6;
	public static final EcsOnTableDelete:UInt32 = 7;

	// Component management

	@:native("flecs_component_get_id_by_name")
	extern public static function getComponentId(name:String):UInt32;

	@:native("flecs_component_is_tag")
	extern public static function isComponentTag(componentId:UInt32):Bool;

	@:native("flecs_component_print_registry")
	extern public static function printComponentRegistry():Void;

	@:native("flecs_component_create")
	extern public static function flecs_component_create(name:String, size:UInt32):UInt32;

	public static function createComponent(name:String, size:UInt32):UInt32 {
		return flecs_component_create(name, size);
	}

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

	// Lifecycle

	@:native("flecs_init")
	extern public static function init():Void;

	@:native("flecs_progress")
	extern public static function progress(delta:Float32):Void;

	@:native("flecs_fini")
	extern public static function fini():Void;

	// Version

	@:native("flecs_version")
	extern public static function flecs_version():ConstCharStar;
	public static function version():String {
		return cast flecs_version();
	}

	// observer

	@:native("flecs_register_observer")
	// extern static function flecs_register_observer(componentIds:cpp.Pointer<UInt32>, numComponents:UInt32, eventIds:cpp.Pointer<UInt32>, numEvents:UInt32,
	//	callback:cpp.Callable<(entityId:UInt32, componentId:UInt32, eventId:UInt32, componentPtr:cpp.RawPointer<cpp.Void>, componentSize:UInt32, callbackId:UInt32) -> Void>, callbackId:UInt32):Bool;
	extern static function flecs_register_observer(componentIds:cpp.Pointer<UInt32>, numComponents:UInt32, eventIds:cpp.Pointer<UInt32>, numEvents:UInt32,
		callback:ObserverCallback, callbackId:UInt32):Bool;

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

		final callbackId = ObserverCallbackRegistry.register(callback);
		final compArrPtr = cpp.Pointer.ofArray(componentsArr);
		final compArrLen = componentsArr.length;
		final eventArrPtr = cpp.Pointer.ofArray(eventsArray);
		final eventArrLen = eventsArray.length;

		// HACK: Call C function directly using untyped __cpp__ and cast trampoline func pointer
		var result:cpp.UInt64 = 0; // Assuming C function returns UInt64 (ecs_entity_t)
		//untyped __cpp__("{5} = flecs_register_observer({0}, {1}, {2}, {3}, (void (*)(unsigned int, unsigned int, unsigned int, void*, unsigned int, unsigned int))hxcore::flecs::ObserverCallbackRegistry_obj::trampoline, {4})",
		//	compArrPtr, compArrLen, eventArrPtr, eventArrLen, callbackId, result);
		//return result != (cast 0 : cpp.UInt64); // Return true if result is non-zero (success)
		return flecs_register_observer(compArrPtr, compArrLen, eventArrPtr, eventArrLen, cpp.Callable.fromStaticFunction(ObserverCallbackRegistry.trampoline), callbackId);
	}

/*
	// system
	// @:native("flecs_register_system")
	// extern public static function flecs_register_system(name:String, component_ids:cpp.Pointer<UInt32>, num_components:UInt32, callback:SystemCallback,
	//		callback_id:UInt32):Bool;

	@:native("flecs_register_system")
	// bool flecs_register_system(const char* name, uint32_t *component_ids, uint32_t num_components, SystemCallback callback, uint32_t callback_id);
	extern static function flecs_register_system(name:String, componentIds:cpp.Pointer<UInt32>, numComponents:UInt32, callback:SystemCallback,
		callbackId:UInt32):Bool;

	// callback:cpp.Callable<(entities:Array<UInt64>, components:Array<cpp.RawPointer<cpp.Void>>, numEntities:UInt32, deltaTime:Float32, callbackId:UInt32) -> Void>, callbackId:UInt32):Bool;

	public static function registerSystem(name:String, componentIds:Array<UInt32>, callback:SystemCallbackHandler):Bool {
		if (componentIds == null)
			return false;
		if (componentIds.length == 0)
			return false;

		// Use standard Array for C interop
		var compIdArr = new Array<UInt32>();
		for (id in componentIds)
			compIdArr.push(id);

		final callbackId = SystemCallbackRegistry.register(callback);
		if (callbackId == 0)
			return false; // Failed to register Haxe callback

		final compArrPtr:cpp.Pointer<UInt32> = cpp.Pointer.ofArray(compIdArr); // <-- Use ofArray
		final compArrLen:UInt32 = cast compIdArr.length;

		// HACK: Call C function directly using untyped __cpp__ and cast trampoline func pointer
		var result:Bool = false; // C function returns bool
		untyped __cpp__( // Cast directly to the C typedef name
			'result = flecs_register_system({0}, {1}, {2}, (SystemCallback)hxcore::flecs::SystemCallbackRegistry_obj::trampoline, {3})',
			name, // {0} - const char* name
			compArrPtr, // {1} - uint32_t* component_ids
			compArrLen, // {2} - uint32_t num_components
			callbackId // {3} - uint32_t callback_id
			// The trampoline function pointer is cast directly in the string literal
		);

		if (!result) {
			Log.warn('Failed to register system "${name}" with Flecs C API.');
			// Optionally unregister the callback handler if C registration failed
			SystemCallbackRegistry.unregister(callbackId); // Might need try/catch if unregister throws
		}

		return result; // Return the boolean result from the C call
	}
	*/
}

typedef ObserverCallbackHandler = (entityId:UInt32, componentId:UInt32, eventId:UInt32, componentPtrInt:UIntPtr) -> Void;

@:keep
class ObserverCallbackRegistry {
	static private var nextCallbackId:UInt32 = 1; // reserve 0 for invalid id
	static private var cbMap:Map<UInt32, ObserverCallbackHandler> = new Map();

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

	public static function unregister(id:UInt32):Bool {
		// TODO:  add an unregister function to the core Flecs library
		// for now, throw an 'unimplemented' error
		throw 'ObserverCallbackRegistry.unregister is unimplemented';
	}

	public static function get(id:UInt32):ObserverCallbackHandler {
		return cbMap.get(id);
	}

	// HACK: Takes componentPtr as pointer-sized unsigned integer (UIntPtr) for Cppia compatibility
	
	//(entityId:UInt32, componentId:UInt32, eventId:UInt32, componentPtr:cpp.RawPointer<cpp.Void>, componentSize:UInt32,
	//	callbackId:UInt32)
	public static function trampoline(entityId:UInt32, componentId:UInt32, eventId:UInt32, componentPtr:cpp.RawPointer<cpp.Void>,
			componentSize:UInt32, callbackId:UInt32):Void {
		Log.debug("in trampoline: " + entityId + " " + componentId + " " + eventId + " " + callbackId);
		var cb:ObserverCallbackHandler = cbMap.get(callbackId);
		if (cb != null) {
			Log.debug("calling callback for id: " + callbackId);
			// Convert the void* to UIntPtr (represented as uintptr_t in C++) before passing to the Haxe handler
			var componentPtrInt:UIntPtr = untyped __cpp__('(uintptr_t){0}', componentPtr);
			//var actualComponentPtr:cpp.RawPointer<cpp.Void> = untyped __cpp__("(void*){0}", componentPtr);
			// Pass pointer (cast to Dynamic) to the actual handler
			cb(entityId, componentId, eventId, componentPtrInt);
		} else {
			Log.warn("no callback found for id: " + callbackId);
		}
	}
}

// Wrapper abstract for void* to help with Array<T> template issues with scriptable
/*
	@:transitive abstract VoidPtr(cpp.RawPointer<cpp.Void>) from cpp.RawPointer<cpp.Void> to cpp.RawPointer<cpp.Void> {
	public inline function new(ptr:cpp.RawPointer<cpp.Void>) {
		this = ptr;
	}
	@:to public inline function toRawPointer():cpp.RawPointer<cpp.Void> {
		return this;
	}
	}
 */
 /*
// Haxe callback signature type
typedef SystemCallbackHandler = (entities:Array<UInt64>, componentsPtr:cpp.Pointer<cpp.RawPointer<cpp.Void>>, numEntities:Int, deltaTime:Float) -> Void;

// C function signature type (matching flecs_wrapper.h)
typedef FlecsSystemCallback = cpp.ConstPointer<UInt64>->UInt32->cpp.Pointer<cpp.RawPointer<cpp.Void>>->UInt32->Float->UInt32->Void;

@:keep
class SystemCallbackRegistry {
	static private var nextCallbackId:UInt32 = 1; // reserve 0 for invalid id
	static private var cbMap:Map<UInt32, SystemCallbackHandler> = new Map();

	public static function register(cb:SystemCallbackHandler, ?id:UInt32):UInt32 {
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

	public static function unregister(id:UInt32):Bool {
		// TODO:  add an unregister function to the core Flecs library
		// for now, throw an 'unimplemented' error
		throw 'ObserverCallbackRegistry.unregister is unimplemented';
	}

	public static function get(id:UInt32):SystemCallbackHandler {
		return cbMap.get(id);
	}

	// HACK: Takes componentPtr as pointer-sized unsigned integer (UIntPtr) for Cppia compatibility
	public static function trampoline(entities:cpp.ConstPointer<UInt64>, numEntities:UInt32, componentsPtr:cpp.Pointer<cpp.RawPointer<cpp.Void>>,
			numComponents:UInt32, deltaTime:Float32, callbackId:UInt32):Void {
		// Log.debug("in trampoline: " + entityId + " " + componentId + " " + eventId + " " + callbackId);
		var cb:SystemCallbackHandler = cbMap.get(callbackId);
		if (cb != null) {
			Log.debug("calling callback for id: " + callbackId);
			var entitiesArr = new Array<UInt64>();
			for (i in 0...numEntities) {
				// Use untyped __cpp__ for direct C++ pointer access
				entitiesArr.push(untyped __cpp__("{0}[{1}]", entities, i));
			}

			// Pass the pointer and counts directly to the actual handler
			cb(entitiesArr, componentsPtr, numEntities, deltaTime);
		} else {
			Log.error("Callback not found for id: " + callbackId);
		}
	}
} // End SystemCallbackRegistry
*/

// known components

/*
	typedef Position = {x:Float32, y:Float32};
	typedef Velocity = {x:Float32, y:Float32};
	typedef Destination = {x:Float32, y:Float32, speed:Float32};
 */
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
