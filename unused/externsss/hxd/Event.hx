package hxd;

@:native("hxd.Event") extern enum EventKind {
	EPush;
	ERelease;
	EMove;
	EOver;
	EOut;
	EWheel;
	EFocus;
	EFocusLost;
	EKeyDown;
	EKeyUp;
	EReleaseOutside;
	ETextInput;
	/**
		
				Used to check if we are still on the interactive if no EMove was triggered this frame.
			
	**/
	ECheck;
}

@:native("hxd.Event") extern class Event {
	function new(k:hxd.Event.EventKind, ?x:Float, ?y:Float):Void;
	var kind : hxd.Event.EventKind;
	var relX : Float;
	var relY : Float;
	var relZ : Float;
	/**
		
				Will propagate the event to other interactives that are below the current one.
			
	**/
	var propagate : Bool;
	/**
		
				Will cancel the default behavior for this event as if it had happen outside of the interactive zone.
			
	**/
	var cancel : Bool;
	var button : Int;
	var touchId : Int;
	var keyCode : Int;
	var charCode : Int;
	var wheelDelta : Float;
	function toString():String;
}