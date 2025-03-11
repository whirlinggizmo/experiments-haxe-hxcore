package h3d.scene;

@:native("h3d.scene.CameraController") extern class CameraController extends h3d.scene.Object {
	function new(?distance:Float, ?parent:h3d.scene.Object):Void;
	var distance(get, never) : Float;
	var targetDistance(get, never) : Float;
	var theta(get, never) : Float;
	var phi(get, never) : Float;
	var fovY(get, never) : Float;
	var target(get, never) : h3d.col.Point;
	var friction : Float;
	var rotateSpeed : Float;
	var zoomAmount : Float;
	var fovZoomAmount : Float;
	var panSpeed : Float;
	var smooth : Float;
	var minDistance : Float;
	var maxDistance : Float;
	var lockZPlanes : Bool;
	var enableZoom : Bool;
	/**
		
				Set the controller parameters.
				Distance is ray distance from target.
				Theta and Phi are the two spherical angles
				Target is the target position
			
	**/
	function set(?distance:Float, ?theta:Float, ?phi:Float, ?target:h3d.col.Point, ?fovY:Float):Void;
	/**
		
				Load current position from current camera position and target.
				Call if you want to modify manually the camera.
			
	**/
	function loadFromCamera(?animate:Bool):Void;
	/**
		
				Initialize to look at the whole scene, based on reported scene bounds.
			
	**/
	function initFromScene():Void;
	/**
		
				Stop animation by directly moving to end position.
				Call after set() if you don't want to animate the change
			
	**/
	function toTarget():Void;
	function onClick(e:hxd.Event):Void;
}