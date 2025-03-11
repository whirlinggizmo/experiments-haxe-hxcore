package h3d.anim;

@:native("h3d.anim.Animation") extern class AnimatedObject {
	function new(name:String):Void;
	var objectName : String;
	var targetObject : h3d.scene.Object;
	var targetSkin : h3d.scene.Skin;
	var targetJoint : Int;
	function clone():h3d.anim.Animation.AnimatedObject;
}

@:native("h3d.anim.Animation") extern class Animation {
	var name : String;
	var resourcePath : String;
	var frameCount(default, null) : Int;
	var sampling(default, null) : Float;
	var frame(default, null) : Float;
	var speed : Float;
	var onAnimEnd : () -> Void;
	var onEvent : String -> Void;
	var pause : Bool;
	var loop : Bool;
	var events(default, null) : Array<Array<String>>;
	function getDuration():Float;
	function unbind(objectName:String):Void;
	/**
		
				Register a callback function that will be called once when a frame is reached.
			
	**/
	function setEvents(el:Iterable<{ public var frame(default, default) : Int; public var data(default, default) : String; }>):Void;
	function addEvent(frame:Int, data:String):Void;
	function removeEvent(frame:Int, data:String):Void;
	function getEvents():Array<Array<String>>;
	function getObjects():Array<h3d.anim.Animation.AnimatedObject>;
	function getEventTime(id:String):Float;
	function setFrame(f:Float):Void;
	function createInstance(base:h3d.scene.Object):h3d.anim.Animation;
	/**
		
				If one of the animated object has been changed, it is necessary to call bind() so the animation can keep with the change.
			
	**/
	@:access(h3d.scene.Skin.skinData)
	function bind(base:h3d.scene.Object):Void;
	/**
		
				Returns the current value of animation property for the given object, or null if not found.
			
	**/
	function getPropValue(objectName:String, propName:String):Float;
	/**
		
				Synchronize the target object matrix.
				If decompose is true, then the rotation quaternion is stored in [m12,m13,m21,m23] instead of mixed with the scale.
			
	**/
	function sync(?decompose:Bool):Void;
	function update(dt:Float):Float;
	function toString():String;
}