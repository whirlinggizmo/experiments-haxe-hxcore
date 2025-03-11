package h3d.prim;

@:native("h3d.prim.Quads") extern class Quads extends h3d.prim.Primitive {
	/**
		
			* You have to pass vertices in this order: top left, top right, bottom left, bottom right
			
	**/
	function new(pts:Array<h3d.col.Point>, ?uvs:Array<h3d.prim.UV>, ?normals:Array<h3d.col.Point>):Void;
	override function getBounds():h3d.col.Bounds;
	override function triCount():Int;
	override function vertexCount():Int;
	function transform(m:h3d.Matrix):Void;
	function translate(dx:Float, dy:Float, dz:Float):Void;
	function scale(x:Float, y:Float, z:Float):Void;
	/**
		
			* Warning : This will splice four basic uv value but can provoke aliasing problems.
			
	**/
	function addUVs():Void;
	override function alloc(engine:h3d.Engine):Void;
	function addNormals():Void;
	function getPoints():Array<h3d.col.Point>;
	override function render(engine:h3d.Engine):Void;
}