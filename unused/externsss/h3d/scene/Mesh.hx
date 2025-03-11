package h3d.scene;

/**
 h3d.scene.Mesh is the base class for all 3D objects displayed on screen.
 Unlike Object base class, all properties of Mesh only apply to the current object and are not inherited by its children.
 */
/**
	
		h3d.scene.Mesh is the base class for all 3D objects displayed on screen.
		Unlike Object base class, all properties of Mesh only apply to the current object and are not inherited by its children.
	
**/
@:native("h3d.scene.Mesh") extern class Mesh extends h3d.scene.Object {
	/**
		
				Creates a new mesh with given primitive, material and parent object.
				If material is not specified, a new default material is created for the current renderer.
			
	**/
	function new(primitive:h3d.prim.Primitive, ?material:h3d.mat.Material, ?parent:h3d.scene.Object):Void;
	/**
		
				The primitive of the mesh: the list of vertexes and indices necessary to display the mesh.
			
	**/
	var primitive(default, set) : h3d.prim.Primitive;
	/**
		
				The material of the mesh: the properties used to display it (texture, color, shaders, etc.)
			
	**/
	var material : h3d.mat.Material;
	/**
		
				When enabled, the lod level is inherited by children objects.
			
	**/
	var inheritLod : Bool;
	/**
		
				Return all materials for the current object.
			
	**/
	function getMeshMaterials():Array<h3d.mat.Material>;
	override function clone(?o:h3d.scene.Object):h3d.scene.Object;
	override function getLocalCollider():h3d.col.Collider;
	override function getMaterialByName(name:String):h3d.mat.Material;
	override function getMaterials(?a:Array<h3d.mat.Material>, ?recursive:Bool):Array<h3d.mat.Material>;
	private function set_primitive(prim:h3d.prim.Primitive):h3d.prim.Primitive;
}