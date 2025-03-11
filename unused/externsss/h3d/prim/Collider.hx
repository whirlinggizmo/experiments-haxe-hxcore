package h3d.prim;

@:access(h3d.prim.HMDModel) @:native("h3d.prim.Collider") extern class Collider {
	function getBuffers():Array<hxd.fmt.hmd.Library.GeometryBuffer>;
	static function fromHmd(hmdModel:h3d.prim.HMDModel):h3d.prim.Collider;
}