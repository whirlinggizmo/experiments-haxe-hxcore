package h3d.scene;

/**
 h3d.scene.Object is the base 3D class that all scene tree elements inherit from.
 It can be used to create a virtual container that does not display anything but can contain other objects
 so the various transforms are inherited to its children.
 */
/**
	
		h3d.scene.Object is the base 3D class that all scene tree elements inherit from.
		It can be used to create a virtual container that does not display anything but can contain other objects
		so the various transforms are inherited to its children.
	
**/
@:native("h3d.scene.Object") extern class Object {
	/**
		
				Create a new empty object, and adds it to the parent object if not null.
			
	**/
	function new(?parent:h3d.scene.Object):Void;
	var currentAnimation(default, null) : h3d.anim.Animation;
	/**
		
				The parent object in the scene tree.
			
	**/
	var parent(default, null) : h3d.scene.Object;
	/**
		
				How many immediate children this object has.
			
	**/
	var numChildren(get, never) : Int;
	/**
		
				Is the object and its children are displayed on screen (default true).
			
	**/
	var visible(get, set) : Bool;
	/**
		
				Inform that the object is not to be displayed and his animation doesn't have to be sync. Unlike visible, this doesn't apply to children unless inheritCulled is set to true.
			
	**/
	var culled(get, set) : Bool;
	/**
		
				When an object is not visible or culled, its animation does not get synchronized unless you set alwaysSyncAnimation=true
			
	**/
	var alwaysSyncAnimation(get, set) : Bool;
	/**
		
				When enabled, the culled flag and culling collider is inherited by children objects.
			
	**/
	var inheritCulled(get, set) : Bool;
	/**
		
				When enabled, the object bounds are ignored when using getBounds()
			
	**/
	var ignoreBounds(get, set) : Bool;
	/**
		
				When enabled, the object is ignored when using getCollider()
			
	**/
	var ignoreCollide(get, set) : Bool;
	/**
		
				Tag the object as a model root
			
	**/
	var modelRoot(get, set) : Bool;
	/**
		
				When enabled, the object will not follow its parent transform
			
	**/
	var ignoreParentTransform(get, set) : Bool;
	/**
		
				When selecting the lights to apply to this object, we will use the camera target as reference
				instead of the object absolute position. This is useful for very large objects so they can get good lighting.
				(this is only relevant in forward rendering)
			
	**/
	var lightCameraCenter(get, set) : Bool;
	/**
		
				When set, the object and all its children will not sync() unless this root object position has been changed.
				This allows to optimize cpu cost of static objects having many children.
				When set, changes on position during sync() won't be applied.
			
	**/
	var fixedPosition(get, set) : Bool;
	/**
		
				When unset, the object and all its children will not sync() if this root object or one of its parent is culled or not visible.
				This allows to optimize cpu cost of objects having many children.
			
	**/
	var alwaysSync(get, set) : Bool;
	/**
		
				When set, the object has been drawn during previous frame. Useful for temporal effects such as temporal antialiasing.
			
	**/
	var drawn(get, set) : Bool;
	/**
		
				When set, collider shape will be used for automatic frustum culling.
				If `inheritCulled` is true, collider will be inherited to children unless they have their own collider set.
			
	**/
	var cullingCollider(default, set) : h3d.col.Collider;
	private function set_cullingCollider(c:h3d.col.Collider):h3d.col.Collider;
	/**
		
				The x position of the object relative to its parent.
			
	**/
	var x(default, set) : Float;
	/**
		
				The y position of the object relative to its parent.
			
	**/
	var y(default, set) : Float;
	/**
		
				The z position of the object relative to its parent.
			
	**/
	var z(default, set) : Float;
	/**
		
				The amount of scaling along the X axis of this object (default 1.0)
			
	**/
	var scaleX(default, set) : Float;
	/**
		
				The amount of scaling along the Y axis of this object (default 1.0)
			
	**/
	var scaleY(default, set) : Float;
	/**
		
				The amount of scaling along the Z axis of this object (default 1.0)
			
	**/
	var scaleZ(default, set) : Float;
	/**
		
				Follow a given object or joint as if it was our parent. Ignore defaultTransform when set.
			
	**/
	var follow(default, set) : h3d.scene.Object;
	/**
		
				When follow is set, only follow the position and ignore both scale and rotation.
			
	**/
	var followPositionOnly(get, set) : Bool;
	/**
		
				This is an additional optional transformation that is performed before other local transformations.
				It is used by the animation system.
			
	**/
	var defaultTransform(default, set) : h3d.Matrix;
	/**
		
				The name of the object, can be used to retrieve an object within a tree by using `getObjectByName` (default null)
			
	**/
	var name : String;
	/**
		
				Create an animation instance bound to the object, set it as currentAnimation and play it.
			
	**/
	function playAnimation(a:h3d.anim.Animation):h3d.anim.Animation;
	/**
		
				Change the current animation. This animation should be an instance that was previously created by playAnimation.
			
	**/
	function switchToAnimation(a:h3d.anim.Animation):h3d.anim.Animation;
	/**
		
				Stop the current animation. If recursive is set to true, all children will also stop their animation
			
	**/
	function stopAnimation(?recursive:Bool):Void;
	/**
		
				When an object is loaded, its position scale and rotation will always be set to the default values (0 for position/rotation and 1 for scale).
				If it's part of a group/scene or if it's animated, then its position/rotation/scale will be stored into the defaultTransform matrix.
				Calling this function will reset the defaultTransform to null and instead initialize x/y/z/rotation/scale properties.
				This will not change the actual position of the object but allows you to move the object more freely on your own.
				Do not use on an object that is currently being animated, since it will set again defaultTransform and apply twice the transformation.
			
	**/
	function applyAnimationTransform(?recursive:Bool):Void;
	/**
		
				Return the total number of children, recursively.
			
	**/
	function getObjectsCount():Int;
	/**
		
				Search for a material recursively by name, return it or null if not found.
			
	**/
	function getMaterialByName(name:String):h3d.mat.Material;
	/**
		
				Tells if the object is contained into this object children, recursively.
			
	**/
	function contains(o:h3d.scene.Object):Bool;
	/**
		
				Find a single object in the tree by calling `f` on each and returning the first not-null value returned, or null if not found.
			
	**/
	function find<T>(f:T):T;
	/**
		
				Find several objects in the tree by calling `f` on each and returning all the not-null values returned.
			
	**/
	function findAll<T>(f:T, ?arr:Array<T>):Array<T>;
	/**
		
				Return all materials in the tree.
			
	**/
	function getMaterials(?a:Array<h3d.mat.Material>, ?recursive:Bool):Array<h3d.mat.Material>;
	/**
		
				Convert a local position (or [0,0] if pt is null) relative to the object origin into an absolute global position, applying all the inherited transforms.
			
	**/
	function localToGlobal(?pt:h3d.col.Point):h3d.col.Point;
	/**
		
				Convert an absolute global position into a local position relative to the object origin, applying all the inherited transforms.
			
	**/
	function globalToLocal(pt:h3d.col.Point):h3d.col.Point;
	/**
		
				Returns the updated inverse position matrix. Please note that this is not a copy and should not be modified.
			
	**/
	function getInvPos():h3d.Matrix;
	/**
		
				Return the bounds of this object and all its children, in absolute global coordinates or relative to the
				object being used as parameter.
			
	**/
	function getBounds(?b:h3d.col.Bounds, ?relativeTo:h3d.scene.Object):h3d.col.Bounds;
	/**
		
				Return all meshes part of this tree
			
	**/
	function getMeshes(?out:Array<h3d.scene.Mesh>):Array<h3d.scene.Mesh>;
	/**
		
				Search for an mesh recursively by name, return null if not found.
			
	**/
	function getMeshByName(name:String):h3d.scene.Mesh;
	/**
		
				Search for an object recursively by name, return null if not found.
			
	**/
	function getObjectByName(name:String):h3d.scene.Object;
	/**
		
				Make a copy of the object and all its children.
			
	**/
	function clone(?o:h3d.scene.Object):h3d.scene.Object;
	/**
		
				Add a child object at the end of the children list.
			
	**/
	function addChild(o:h3d.scene.Object):Void;
	/**
		
				Insert a child object at the specified position of the children list.
			
	**/
	function addChildAt(o:h3d.scene.Object, pos:Int):Void;
	/**
		
				Iterate on all mesh that are currently visible and not culled in the tree. Call `callb` for each mesh found.
			
	**/
	function iterVisibleMeshes(callb:h3d.scene.Mesh -> Void):Void;
	/**
		
				Remove the given object from our immediate children list if it's part of it.
			
	**/
	function removeChild(o:h3d.scene.Object):Void;
	/**
		
				Remove all children from our immediate children list
			
	**/
	function removeChildren():Void;
	/**
		
				Return the Scene this object is part of, or null if not added to a Scene.
			
	**/
	function getScene():h3d.scene.Scene;
	/**
		
				Returns the updated absolute position matrix. Please note that this is not a copy so it should not be modified.
			
	**/
	function getAbsPos():h3d.Matrix;
	/**
		
				Returns the position matrix relative to another scene object
			
	**/
	function getRelPos(obj:h3d.scene.Object):h3d.Matrix;
	/**
		
				If the object is a Mesh, return the corresponding Mesh. If not, throw an exception.
			
	**/
	function toMesh():h3d.scene.Mesh;
	/**
		
				Build and return the global absolute recursive collider for the object.
				Returns null if no collider was found or if ignoreCollide was set to true.
			
	**/
	function getCollider():h3d.col.Collider;
	/**
		
				Same as getLocalCollider, but returns an absolute collider instead of a local one.
			
	**/
	function getGlobalCollider():h3d.col.Collider;
	/**
		
				Build and returns the local relative not-recursive collider for the object, or null if this object does not have a collider.
				Does not check for ignoreCollide.
			
	**/
	function getLocalCollider():h3d.col.Collider;
	private function set_follow(v:h3d.scene.Object):h3d.scene.Object;
	function setTransform(mat:h3d.Matrix):Void;
	/**
		
				Returns the local position, scale and rotation of the object relative to its parent.
			
	**/
	function getTransform(?mat:h3d.Matrix):h3d.Matrix;
	/**
		
				Rotate around the current rotation axis by the specified angles (in radian).
			
	**/
	function rotate(rx:Float, ry:Float, rz:Float, ?qTmp:h3d.Quat):Void;
	/**
		
				Set the rotation using the specified angles (in radian).
			
	**/
	function setRotation(rx:Float, ry:Float, rz:Float):Void;
	/**
		
				Set the rotation using the specified axis and angle of rotation around it (in radian).
			
	**/
	function setRotationAxis(ax:Float, ay:Float, az:Float, angle:Float):Void;
	/**
		
				Set the rotation using the specified look at direction
			
	**/
	function setDirection(v:h3d.Vector, ?up:h3d.Vector):Void;
	/**
		
				Return the direction in which the object rotation is currently oriented to
			
	**/
	function getLocalDirection():h3d.Vector;
	/**
		
				Return the quaternion representing the current object rotation.
				Dot not modify as it's not a copy.
			
	**/
	function getRotationQuat():h3d.Quat;
	/**
		
				Set the quaternion representing the current object rotation.
				Dot not modify the value afterwards as no copy is made.
			
	**/
	function setRotationQuat(q:h3d.Quat):Void;
	/**
		
				Return both class name and object name if any.
			
	**/
	function toString():String;
	/**
		
				Return the index of the object `o` within our immediate children list, or `-1` if it is not part of our children list.
			
	**/
	function getChildIndex(o:h3d.scene.Object):Int;
}

@:enum typedef ObjectFlags = Int;