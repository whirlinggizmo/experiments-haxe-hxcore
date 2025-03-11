package h3d.prim;

@:access(h3d.prim.HMDModel) @:native("h3d.prim.Blendshape") extern class Blendshape {
	function new(hmdModel:h3d.prim.HMDModel):Void;
	function setBlendshapeAmount(blendshapeIdx:Int, amount:Float):Void;
}