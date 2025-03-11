package h3d;

@:native("h3d.Camera") extern class Camera {
	function new(?fovY:Float, ?zoom:Float, ?screenRatio:Float, ?zNear:Float, ?zFar:Float, ?rightHanded:Bool):Void;
	var zoom : Float;
	/**
		
				The screenRatio represents the W/H screen ratio.
			 
	**/
	var screenRatio : Float;
	/**
		
				The vertical FieldOfView, in degrees.
				Usually cameras are using an horizontal FOV, but the value will change depending on the screen ratio.
				For instance a 4:3 screen will have a lower horizontal FOV than a 16:9 one, however the vertical FOV remains constant.
				Use setFovX to initialize fovY based on an horizontal FOV and an initial screen ratio.
			
	**/
	var fovY : Float;
	var zNear : Float;
	var zFar : Float;
	/**
		
				Set orthographic bounds.
			
	**/
	var orthoBounds : h3d.col.Bounds;
	var rightHanded : Bool;
	var mproj : h3d.Matrix;
	var mcam : h3d.Matrix;
	var m : h3d.Matrix;
	var pos : h3d.Vector;
	/**
		
				up is used for the lookAt matrix.
				it is not the actual up axis of the camera.
				use getUp instead.
			
	**/
	var up : h3d.Vector;
	var target : h3d.Vector;
	var viewX : Float;
	var viewY : Float;
	var follow : { var pos : h3d.scene.Object; var target : h3d.scene.Object; };
	var frustum(default, null) : h3d.col.Frustum;
	var jitterOffsetX : Float;
	var jitterOffsetY : Float;
	/**
		
				Set the vertical fov based on a given horizontal fov (in degrees) for a specified screen ratio.
			
	**/
	function setFovX(fovX:Float, withRatio:Float):Void;
	/**
		
				Calculate the current horizontal fov (in degrees).
			
	**/
	function getFovX():Float;
	function clone():h3d.Camera;
	/**
		
				Returns the inverse of the camera matrix view and projection. Cache the result until the next update().
			
	**/
	function getInverseViewProj():h3d.Matrix;
	/**
		
				Returns the inverse of the camera matrix projection. Cache the result until the next update().
			
	**/
	function getInverseProj():h3d.Matrix;
	/**
		
				Returns the inverse of the camera matrix view only. Cache the result until the next update().
			
	**/
	function getInverseView():h3d.Matrix;
	/**
		
				Setup camera for cubemap rendering on the given face.
			
	**/
	function setCubeMap(face:Int, ?position:h3d.Vector):Void;
	/**
		
				Transforms a 2D screen position into the 3D one according to the current camera.
				The screenX and screenY values must be in the [-1,1] range.
				The camZ value represents the normalized z in the frustum in the [0,1] range.
				[unproject] can be used to get the ray from the camera position to a given screen position by using two different camZ values.
				For instance the 3D ray between unproject(0,0,0) and unproject(0,0,1) is the center axis of the 3D frustum.
			
	**/
	function unproject(screenX:Float, screenY:Float, camZ:Float):h3d.Vector;
	function rayFromScreen(pixelX:Float, pixelY:Float, ?sceneWidth:Int, ?sceneHeight:Int):h3d.col.Ray;
	function update():Void;
	function getFrustumCorners(?zMax:Float, ?zMin:Float):Array<h3d.Vector>;
	function lostUp():Bool;
	function getViewDirection(dx:Float, dy:Float, ?dz:Float):h3d.Vector;
	function movePosAxis(dx:Float, dy:Float, ?dz:Float):Void;
	function moveTargetAxis(dx:Float, dy:Float, ?dz:Float):Void;
	function forward(?speed:Float):Void;
	function backward(?speed:Float):Void;
	function setTransform(m:h3d.Matrix):Void;
	function project(x:Float, y:Float, z:Float, screenWidth:Float, screenHeight:Float, ?snapToPixel:Bool, ?p:h3d.Vector):h3d.Vector;
	function distanceToDepth(dist:Float):Float;
	function depthToDistance(depth:Float):Float;
	function load(cam:h3d.Camera):Void;
}