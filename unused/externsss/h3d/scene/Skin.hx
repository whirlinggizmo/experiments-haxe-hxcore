package h3d.scene;

@:native("h3d.scene.Skin") extern class Joint extends h3d.scene.Object {
	function new(skin:h3d.scene.Skin, j:h3d.anim.Skin.Joint):Void;
	var skin : h3d.scene.Skin;
	var index : Int;
	override function getObjectByName(name:String):h3d.scene.Skin.Joint;
	/**
		
				Force the update of the position of this joint
			
	**/
	@:access(h3d.scene.Skin)
	function update():Void;
}

@:access(h3d.scene.Skin) @:native("h3d.scene.Skin") extern class JointData {
	function new():Void;
	var currentRelPose : h3d.Matrix;
	var currentAbsPose : h3d.Matrix;
	var additivePose : h3d.Matrix;
	function sync(skin:h3d.scene.Skin, j:h3d.anim.Skin.Joint):Void;
}

@:access(h3d.scene.Skin) @:native("h3d.scene.Skin") extern class DynamicJointData extends h3d.scene.Skin.JointData {
	function new():Void;
	var absPos : h3d.Matrix;
	var relPos : h3d.Matrix;
	var speed : h3d.Vector;
	function load(data:h3d.scene.Skin.DynamicJointData):Void;
	override function sync(skin:h3d.scene.Skin, j:h3d.anim.Skin.Joint):Void;
}

@:native("h3d.scene.Skin") extern class Skin extends h3d.scene.MultiMaterial {
	function new(s:h3d.anim.Skin, ?mat:Array<h3d.mat.Material>, ?parent:h3d.scene.Object):Void;
	var showJoints : Bool;
	var enableRetargeting : Bool;
	var prevEnableRetargeting : Bool;
	override function clone(?o:h3d.scene.Object):h3d.scene.Skin;
	function getCurrentSkeletonBounds():h3d.col.Bounds;
	override function getObjectByName(name:String):h3d.scene.Object;
	override function getLocalCollider():h3d.col.Collider;
	override function getGlobalCollider():h3d.col.SkinCollider;
	function getSkinData():h3d.anim.Skin;
	function getJointRelPosition(name:String, ?additive:Bool):h3d.Matrix;
	function setJointRelPosition(name:String, pos:h3d.Matrix, ?additive:Bool):Void;
	function setSkinData(s:h3d.anim.Skin, ?shaderInit:Bool):Void;
}