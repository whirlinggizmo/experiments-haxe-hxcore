package h3d.prim;

typedef ModelDataInput = {
	var hmd : h3d.prim.HMDModel;
	var objectName : String;
	var resourceDirectory : String;
	var resourceName : String;
	var skin : h3d.scene.Skin;
};

@:native("h3d.prim.ModelDatabase") extern class ModelDatabase {
	function loadModelProps(input:h3d.prim.ModelDatabase.ModelDataInput):Void;
	function saveModelProps(input:h3d.prim.ModelDatabase.ModelDataInput):Void;
	static var db : Map<String, Dynamic>;
	static var current : h3d.prim.ModelDatabase;
}