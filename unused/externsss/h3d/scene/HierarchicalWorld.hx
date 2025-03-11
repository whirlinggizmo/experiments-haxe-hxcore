package h3d.scene;

typedef WorldData = {
	var depth : Int;
	var maxDepth : Int;
	var onCreate : h3d.scene.HierarchicalWorld -> Void;
	var root : h3d.scene.HierarchicalWorld;
	var size : Int;
	var subdivPow : Float;
	var x : Int;
	var y : Int;
};

@:native("h3d.scene.HierarchicalWorld") extern class HierarchicalWorld extends h3d.scene.Object {
	function new(parent:h3d.scene.Object, data:h3d.scene.HierarchicalWorld.WorldData):Void;
	var data : h3d.scene.HierarchicalWorld.WorldData;
	var level(get, null) : Int;
	function get_level():Int;
	function getChunkPos(x:Float, y:Float, ?depth:Int):h2d.col.Point;
	function containsAt(x:Float, y:Float):Bool;
	function requestCreateAt(x:Float, y:Float, lock:Bool):Void;
	function getChunkAtLock(x:Float, y:Float):h3d.scene.HierarchicalWorld;
	function lockAt(x:Float, y:Float):Void;
	function unlockAt(x:Float, y:Float):Void;
	function unlockAll():Void;
	function getRoot():h3d.scene.HierarchicalWorld;
	function refresh():Void;
	static var FULL : Bool;
	static var DEBUG : Bool;
}