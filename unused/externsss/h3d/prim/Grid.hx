package h3d.prim;

@:native("h3d.prim.Grid") extern class Grid extends h3d.prim.Polygon {
	function new(width:Int, height:Int, ?cellWidth:Float, ?cellHeight:Float):Void;
	var width(default, null) : Int;
	var height(default, null) : Int;
	var cellWidth(default, null) : Float;
	var cellHeight(default, null) : Float;
	override function addUVs():Void;
}