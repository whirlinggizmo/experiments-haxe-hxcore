package h3d.prim;

/**
 Vertex buffers are limited to 65K vertexes because of the 16-bits limitation of the index buffers.
 BigPrimitive allows you to easily create large buffers by spliting the buffers.
 */
/**
	
		Vertex buffers are limited to 65K vertexes because of the 16-bits limitation of the index buffers.
		BigPrimitive allows you to easily create large buffers by spliting the buffers.
	
**/
@:native("h3d.prim.BigPrimitive") extern class BigPrimitive extends h3d.prim.Primitive {
	function new(format:hxd.BufferFormat, ?alloc:hxd.impl.Allocator):Void;
	var format(default, null) : hxd.BufferFormat;
	var hasTangents : Bool;
	var isStatic : Bool;
	/**
		
				Call begin() before starting to add vertexes/indexes to the primitive.
				The count value is the number of vertexes you will add, it will automatically flush() if it doesn't fit into the current buffer.
			
	**/
	function begin(vcount:Int, icount:Int):Void;
	override function triCount():Int;
	override function vertexCount():Int;
	/**
		
				Flush the current buffer.
				It is required to call begin() after a flush()
			
	**/
	function flush():Void;
	override function render(engine:h3d.Engine):Void;
	override function getBounds():h3d.col.Bounds;
	override function dispose():Void;
	function clear():Void;
	/**
		
				Adds a complete object to the primitive, with custom position,scale,rotation.
				See addSub for complete documentation.
			
	**/
	function add(buf:hxd.FloatBuffer, idx:hxd.IndexBuffer, ?dx:Float, ?dy:Float, ?dz:Float, ?rotation:Float, ?scale:Float, ?stride:Int):Void;
	/**
		
				Adds a buffer to the primitive, with custom position,scale,rotation.
				The buffer can have more stride than the BigPrimitive, but not less.
				It is assumed that the buffer contains [X,Y,Z,NX,NY,NZ,U,V,R,G,B] (depending on his stride) so the different offsets are applied to the corresponding components.
				If hasTangent=true, we have [TX,TY,TZ] just after normal.
				However if the stride is 5, we assume [X,Y,Z,U,V]
				If mat is not null, it overrides dx, dy, dz, rotation, scale
			
	**/
	@:noDebug
	function addSub(buf:hxd.FloatBuffer, idx:hxd.IndexBuffer, startVert:Int, startTri:Int, nvert:Int, triCount:Int, ?dx:Float, ?dy:Float, ?dz:Float, ?rotation:Float, ?scale:Float, ?stride:Int, ?deltaU:Float, ?deltaV:Float, ?color:Float, ?mat:h3d.Matrix):Void;
}