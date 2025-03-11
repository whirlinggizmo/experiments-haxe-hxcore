package h3d;

@:noDebug @:native("h3d.Quat") extern class Quat {
	var x : Float;
	var y : Float;
	var z : Float;
	var w : Float;
	function clone():h3d.Quat;
	function initMoveTo(from:h3d.Vector, to:h3d.Vector):Void;
	function initNormal(dir:h3d.col.Point, ?rotate:Float):Void;
	function initDirection(dir:h3d.Vector, ?up:h3d.Vector):Void;
	function initRotateAxis(x:Float, y:Float, z:Float, a:Float):Void;
	function initRotateMatrix(m:h3d.Matrix):Void;
	function normalize():Void;
	function initRotation(ax:Float, ay:Float, az:Float):Void;
	function multiply(q1:h3d.Quat, q2:h3d.Quat):Void;
	function toEuler():h3d.Vector;
	function slerp(q1:h3d.Quat, q2:h3d.Quat, v:Float):Void;
	/**
		
				Save to a Left-Handed matrix
			
	**/
	function toMatrix(?m:h3d.Matrix):h3d.Matrix;
	function toString():String;
	/**
		
				Blends the sourceQuats together with the given weights and store the result in `this`.
				ReferenceQuat is the default rotation to use as the base for the blend
				(for example the default rotation of a bone in a skeletal mesh)
			
	**/
	function weightedBlend(sourceQuats:Array<h3d.Quat>, weights:Array<Float>, referenceQuat:h3d.Quat):Void;
}