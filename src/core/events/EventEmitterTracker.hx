package core.events;

import core.logging.Log;

// EventEmitterTracker
// Helper class for tracking registered event listeners
// Springboards to an EventEmitter instance
// This allows us to track the event listeners locally so we can remove
// specific listeners or all listeners when needed  (e.g. a script).
class EventEmitterTracker extends EventEmitter {
	// track the event listeners so we can remove them later
	private var registeredEvents:Map<String, Array<Dynamic->Void>> = new Map();

	@:isVar
	public var eventEmitter(get, set):EventEmitter;

	public function get_eventEmitter():EventEmitter {
		return eventEmitter;
	}

	public function set_eventEmitter(value:EventEmitter):EventEmitter {
		if (this.eventEmitter != null) {
			Log.debug("EventEmitterTracker: Clearing all event listeners.");
			this.clearAll();
		}
		eventEmitter = value;
		return eventEmitter;
	}

	public function new(eventEmitter:EventEmitter = null) {
		super();
		this.eventEmitter = eventEmitter;
	}

	// EventEmitter interface for scripts
	override public function on(event:String, callback:Dynamic->Void):Void {
		if (this.eventEmitter == null) {
			Log.debug("No external event emitter set.");
			return;
		}
		eventEmitter.on(event, callback);

		// track the event listeners so we can remove them later
		if (!registeredEvents.exists(event)) {
			registeredEvents.set(event, []);
		}
		registeredEvents.get(event).push(callback);
	}

	override public function off(event:String, callback:Dynamic->Void):Void {
		if (this.eventEmitter == null) {
			Log.debug("No external event emitter set.");
			return;
		}

		eventEmitter.off(event, callback);

		// untrack the event listeners, removing them from the internal event emitter
		if (registeredEvents.exists(event)) {
			var listeners = registeredEvents.get(event);
			listeners.remove(callback);
			if (listeners.length == 0) {
				registeredEvents.remove(event);
			}
		}
	}

	override public function emit(event:String, ?data:Dynamic):Void {
		if (this.eventEmitter == null) {
			Log.debug("No external event emitter set.");
			return;
		}
		eventEmitter.emit(event, data);
	}

	override public function clear(event:String):Void {
		// remove the event listeners from the external event emitter
		for (callback in registeredEvents.get(event)) {
			off(event, callback);
		}
	}

	override public function clearAll():Void {
		// remove all event listeners from the external event emitter
		for (event in registeredEvents.keys()) {
			clear(event);
		}
	}
}
