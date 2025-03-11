package h3d.prim;

/**
 h3d.prim.Primitive is the base class for all 3D primitives.
 You can't create an instance of it and need to use one of its subclasses.
 */
/**
	
		h3d.prim.Primitive is the base class for all 3D primitives.
		You can't create an instance of it and need to use one of its subclasses.
	
**/
@:native("h3d.prim.Primitive") extern class Primitive {
	/**
		
				The primitive vertex buffer, holding its vertexes data.
			
	**/
	var buffer : h3d.Buffer;
	/**
		
				The primitive indexes buffer, holding its triangles indices.
			
	**/
	var indexes : h3d.Indexes;
	/**
		
				Allow user to force a specific lod index. If set to -1, forced lod will be ignored.
			
	**/
	var forcedLod : Int;
	/**
		
				Current amount of references to this Primitive.
				Use `incref` and `decref` methods to affect this value. If it reaches 0, it will be atuomatically disposed.
			
	**/
	var refCount(default, null) : Int;
	/**
		
				The number of triangles the primitive has.
			
	**/
	function triCount():Int;
	/**
		
				The number of vertexes the primitive has.
			
	**/
	function vertexCount():Int;
	/**
		
				Return a local collider for the primitive
			
	**/
	function getCollider():h3d.col.Collider;
	/**
		
				Return the bounds for the primitive
			
	**/
	function getBounds():h3d.col.Bounds;
	/**
		
				Increase reference count of the Primitive.
			
	**/
	function incref():Void;
	/**
		
				Decrease reference count of the Primitive.
				If recount reaches zero, Primitive is automatically disposed when last referencing mesh is removed from scene.
			
	**/
	function decref():Void;
	/**
		
				Allocate the primitive on GPU. Used for internal usage.
			
	**/
	function alloc(engine:h3d.Engine):Void;
	/**
		
				Select the specified sub material before drawin. Used for internal usage.
			
	**/
	function selectMaterial(material:Int, lod:Int):Void;
	/**
		
				Returns the number and offset of indexes for the specified material
			
	**/
	function getMaterialIndexes(material:Int, ?lod:Int):{ var count : Int; var start : Int; };
	function getMaterialIndexStart(material:Int, ?lod:Int):Int;
	function getMaterialIndexCount(material:Int, ?lod:Int):Int;
	@:noCompletion
	function buildNormalsDisplay():h3d.prim.Primitive;
	/**
		
				Render the primitive. Used for internal usage.
			
	**/
	function render(engine:h3d.Engine):Void;
	/**
		
				Dispose the primitive, freeing the GPU memory it uses.
			
	**/
	function dispose():Void;
	/**
		
				Return the primitive type.
			
	**/
	function toString():String;
	/**
		
			 	Return the LOD count.
			
	**/
	function lodCount():Int;
	function screenRatioToLod(screenRatio:Float):Int;
}