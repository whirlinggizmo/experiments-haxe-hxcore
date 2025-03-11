package h2d.col._Voronoi;

@:noDoc @:native("h2d.col._Voronoi.RBTree_h2d_col__Voronoi_Beachsection") extern class RBTree_h2d_col__Voronoi_Beachsection {
	function new():Void;
	var root : Beachsection;
	function rbInsertSuccessor(node:Beachsection, successor:Beachsection):Void;
	function rbRemoveNode(node:Beachsection):Void;
	function getFirst(node:Beachsection):Beachsection;
	function getLast(node:Beachsection):Beachsection;
}