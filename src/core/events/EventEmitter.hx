package core.events;


typedef EventListener = (args:Dynamic) -> Void;

class EventEmitter {
	// A map where the keys are event names (Strings) and the values are arrays of listeners (functions).
	private var events:Map<String, Array<EventListener>> = new Map();

	// constructor
	public function new() {
		// A map where the keys are event names (Strings) and the values are arrays of listeners (functions).
		this.events = new Map();
	}

	/**
	 * Registers an event listener for the specified event.
	 * 
	 * @param event The event name.
	 * @param listener The function to be called when the event is emitted.
	 */
	public function on(event:String, listener:EventListener):Void {
		if (!events.exists(event)) {
			events.set(event, []);
		}
		events.get(event).push(listener);
	}

	/**
	 * Removes a specific listener for the specified event.
	 * 
	 * @param event The event name.
	 * @param listener The function to be removed.
	 */
	public function off(event:String, listener:EventListener):Void {
		if (events.exists(event)) {
			var listeners = events.get(event);
			listeners.remove(listener); // Removes the listener
			if (listeners.length == 0) {
				events.remove(event); // If no listeners left, remove the event
			}
		}
	}

	/**
	 * Emits an event, calling all registered listeners for that event.
	 * 
	 * @param event The event name.
	 * @param data The event data passed to each listener.
	 */
	public function emit(event:String, ?data:Dynamic):Void {
		if (events.exists(event)) {
			var listeners = events.get(event);//.copy(); // Copy to avoid modification during iteration
			for (listener in listeners) {
				listener(data ?? {});
			}
		}
	}

	public function getListeners(event:String):Array<EventListener> {
		return events.get(event);
	}

	public function getEvents():Iterator<String> {
		return events.keys();
	}

	/**
	 * Clears all listeners for the specified event.
	 * 
	 * @param event The event name.
	 */
	public function clear(event:String):Void {
		var eventListeners = events.get(event);
		if (eventListeners != null) {
			eventListeners = []; // Clears the listeners
		}
		events.remove(event);
	}

	/**
	 * Clears all listeners for all events.
	 */
	public function clearAll():Void {
		for (event in events.keys()) {
			clear(event);
		}
		events = new Map(); // Resets the event map
	}
}
