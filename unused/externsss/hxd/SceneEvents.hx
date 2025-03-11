package hxd;

interface Interactive {
	var propagateEvents : Bool;
	var cursor(default, set) : hxd.Cursor;
	function handleEvent(e:hxd.Event):Void;
	function getInteractiveScene():hxd.SceneEvents.InteractiveScene;
}

interface InteractiveScene {
	function setEvents(s:hxd.SceneEvents):Void;
	function handleEvent(e:hxd.Event, last:hxd.SceneEvents.Interactive):hxd.SceneEvents.Interactive;
	function dispatchEvent(e:hxd.Event, to:hxd.SceneEvents.Interactive):Void;
	function dispatchListeners(e:hxd.Event):Void;
	function isInteractiveVisible(i:hxd.SceneEvents.Interactive):Bool;
}

@:native("hxd.SceneEvents") extern class SceneEvents {
	function new(?window:Dynamic):Void;
	/**
		
			 * enablePhysicalMouse : enable mouse movements of system mouse, set it to false anse use setMousePos instead to manually set mouse position
			 
	**/
	var enablePhysicalMouse : Bool;
	/**
		
			 * enable/disable per frame check of elements under mouse (default:true)
			 
	**/
	var mouseCheckMove : Bool;
	/**
		
			 * Default cursor when there is no Interactive present under cursor.
			 
	**/
	var defaultCursor(default, set) : hxd.Cursor;
	function setMousePos(xPos:Float, yPos:Float):Void;
	function addScene(s:hxd.SceneEvents.InteractiveScene, ?index:Int):Void;
	function removeScene(s:hxd.SceneEvents.InteractiveScene):Void;
	function dispose():Void;
	function focus(i:hxd.SceneEvents.Interactive):Void;
	function blur():Void;
	function checkEvents():Void;
	function startCapture(f:hxd.Event -> Void, ?onCancel:() -> Void, ?touchId:Int):Void;
	function stopCapture():Void;
	function getFocus():hxd.SceneEvents.Interactive;
	function updateCursor(i:hxd.SceneEvents.Interactive):Void;
	private function set_defaultCursor(c:hxd.Cursor):hxd.Cursor;
}