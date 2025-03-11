package h3d.scene;

@:native("h3d.scene.Interactive") extern class Interactive extends h3d.scene.Object implements hxd.SceneEvents.Interactive {
	function new(shape:h3d.col.Collider, ?parent:h3d.scene.Object):Void;
	var shape : h3d.col.Collider;
	/**
		
				If several interactive conflicts, the preciseShape (if defined) can be used to distinguish between the two.
			
	**/
	var preciseShape : h3d.col.Collider;
	/**
		
				In case of conflicting shapes, usually the one in front of the camera is prioritized, unless you set an higher priority.
			
	**/
	var priority : Int;
	var cursor(default, set) : hxd.Cursor;
	/**
		
				Set the default `cancel` mode (see `hxd.Event`), default to false.
			
	**/
	var cancelEvents : Bool;
	/**
		
				Set the default `propagate` mode (see `hxd.Event`), default to false.
			
	**/
	var propagateEvents : Bool;
	/**
		
				When enabled, interacting with secondary mouse buttons (right button/wheel) will cause `onPush`, `onClick`, `onRelease` and `onReleaseOutside` callbacks.
				Otherwise those callbacks will only be triggered with primary mouse button (left button).
			
	**/
	var enableRightButton : Bool;
	/**
		
			 	When enabled, allows to receive several onClick events the same frame.
			
	**/
	var allowMultiClick : Bool;
	/**
		
				Is it required to find the best hit point in a complex mesh or any hit possible point will be enough (default = false, faster).
			
	**/
	var bestMatch : Bool;
	/**
		
			 	When set, will display the debug object of the shape (using makeDebugObj)
			
	**/
	var showDebug(get, set) : Bool;
	/**
		
			 *  Tells if our shapes are in absolute space (for example ObjectCollider) or relative to the interactive transform.
			 
	**/
	var isAbsoluteShape : Bool;
	var emittedLastFrame : Bool;
	function getPoint(ray:h3d.col.Ray, bestMatch:Bool):h3d.Vector;
	function set_showDebug(val:Bool):Bool;
	/**
		
				This can be called during or after a push event in order to prevent the release from triggering a click.
			
	**/
	function preventClick():Void;
	@:noCompletion
	function getInteractiveScene():hxd.SceneEvents.InteractiveScene;
	@:noCompletion
	function handleEvent(e:hxd.Event):Void;
	private function set_cursor(c:hxd.Cursor):hxd.Cursor;
	function focus():Void;
	function blur():Void;
	function isOver():Bool;
	function hasFocus():Bool;
	/**
		
				Sent when mouse enters Interactive hitbox area.
				`event.propagate` and `event.cancel` are ignored during `onOver`.
				Propagation can be set with `onMove` event, as well as cancelling `onMove` will prevent `onOver`.
			
	**/
	function onOver(e:hxd.Event):Void;
	/**
		 Sent when mouse exits Interactive hitbox area.
				`event.propagate` and `event.cancel` are ignored during `onOut`.
			
	**/
	function onOut(e:hxd.Event):Void;
	/**
		 Sent when Interactive is pressed by user. 
	**/
	function onPush(e:hxd.Event):Void;
	/**
		
				Sent on multiple conditions.
				A. Always sent if user releases mouse while it is inside Interactive hitbox area.
					This happends regardless if that Interactive was pressed prior or not.
				B. Sent before `onReleaseOutside` if this Interactive was pressed, but released outside it's bounds.
				For first case `event.kind` will be `ERelease`, for second case - `EReleaseOutside`.
				See `onClick` and `onReleaseOutside` functions for separate events that trigger only when user interacts with this particular Interactive.
			
	**/
	function onRelease(e:hxd.Event):Void;
	/**
		
				Sent when user presses Interactive, moves mouse outside and releases it.
				This event fired only on Interactive that user pressed, but released mouse after moving it outside of Interactive hitbox area.
			
	**/
	function onReleaseOutside(e:hxd.Event):Void;
	/**
		
				Sent when Interactive is clicked by user.
				This event fired only on Interactive that user pressed and released when mouse is inside Interactive hitbox area.
			
	**/
	function onClick(e:hxd.Event):Void;
	function onMove(e:hxd.Event):Void;
	function onWheel(e:hxd.Event):Void;
	function onFocus(e:hxd.Event):Void;
	function onFocusLost(e:hxd.Event):Void;
	function onKeyUp(e:hxd.Event):Void;
	function onKeyDown(e:hxd.Event):Void;
	function onCheck(e:hxd.Event):Void;
	function onTextInput(e:hxd.Event):Void;
	static function setupDebugMaterial(debugObj:h3d.scene.Object):Void;
}