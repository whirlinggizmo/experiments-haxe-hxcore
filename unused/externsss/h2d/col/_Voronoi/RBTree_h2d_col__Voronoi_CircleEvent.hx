package h2d.col._Voronoi;

@:noDoc @:native("h2d.col._Voronoi.RBTree_h2d_col__Voronoi_CircleEvent") extern class RBTree_h2d_col__Voronoi_CircleEvent {
	function new():Void;
	var root : CircleEvent;
	function rbInsertSuccessor(node:CircleEvent, successor:CircleEvent):Void;
	function rbRemoveNode(node:CircleEvent):Void;
	function getFirst(node:CircleEvent):CircleEvent;
	function getLast(node:CircleEvent):CircleEvent;
}