package h3d.scene;

/**
 h3d.scene.MeshBatch allows to draw multiple meshed in a single draw call.
 See samples/MeshBatch.hx for an example.
 */
/**
	
		h3d.scene.MeshBatch allows to draw multiple meshed in a single draw call.
		See samples/MeshBatch.hx for an example.
	
**/
@:native("h3d.scene.MeshBatch") extern class MeshBatch extends h3d.scene.MultiMaterial {
	function new(primitive:h3d.prim.MeshPrimitive, ?material:h3d.mat.Material, ?parent:h3d.scene.Object):Void;
	var lodDistance : Float;
	var meshBatchFlags(default, null) : haxe.EnumFlags<h3d.scene.MeshBatch.MeshBatchFlag>;
	var maxDistance : Float;
	/**
		
				Set if shader list or shader constants has changed, before calling begin()
			
	**/
	var shadersChanged : Bool;
	/**
		
				The number of instances on this batch
			
	**/
	var instanceCount(default, null) : Int;
	/**
		
			 * 	If set, use this position in emitInstance() instead MeshBatch absolute position
			
	**/
	var worldPosition : h3d.Matrix;
	/**
		
				Tells the mesh batch to draw only a subpart of the primitive
			
	**/
	var primitiveSubPart : h3d.scene.MeshBatch.MeshBatchPart;
	/**
		
				If set, exact bounds will be recalculated during emitInstance (default true)
			
	**/
	var calcBounds : Bool;
	function begin(?emitCountTip:Int, ?flags:haxe.EnumFlags<h3d.scene.MeshBatch.MeshBatchFlag>):Void;
	function emitInstance():Void;
	function disposeBuffers(?useAllocator:Bool):Void;
	function flush():Void;
}

@:native("h3d.scene.MeshBatch") extern class BatchData {
	function new():Void;
	var paramsCount : Int;
	var maxInstance : Int;
	var matIndex : Int;
	var indexCount : Int;
	var indexStart : Int;
	var instanceBuffers : Array<h3d.impl.InstanceBuffer>;
	var buffers : Array<h3d.Buffer>;
	var bufferFormat : hxd.BufferFormat;
	var data : hxd.FloatBuffer;
	var params : hxsl.RuntimeShader.AllocParam;
	var shader : hxsl.BatchShader;
	var shaders : Array<hxsl.Shader>;
	var modelViewPos : Int;
	var pass : h3d.mat.Pass;
	var computePass : h3d.mat.Pass;
	var commandBuffers : Array<h3d.Buffer>;
	var countBuffers : Array<h3d.Buffer>;
	var next : h3d.scene.MeshBatch.BatchData;
}

@:native("h3d.scene.MeshBatch") extern class MeshBatchPart {
	function new():Void;
	var indexStart : Int;
	var indexCount : Int;
	var lodIndexStart : Array<Int>;
	var lodIndexCount : Array<Int>;
	var lodConfig : Array<Float>;
	var baseVertex : Int;
	var bounds : h3d.col.Bounds;
	function clone():h3d.scene.MeshBatch.MeshBatchPart;
}

@:native("h3d.scene.MeshBatch") extern enum MeshBatchFlag {
	EnableGpuCulling;
	EnableLod;
	EnableResizeDown;
	EnableGpuUpdate;
	EnableStorageBuffer;
}

@:src({
		@global var camera:{ var position : Vec3; };
		@const var ENABLE_COUNT_BUFFER:Bool;
		@param var countBuffer:RWBuffer<Int>;
		@param var instanceOffsets:StorageBuffer<Int>;
		@param var commandBuffer:RWBuffer<Int>;
		@param var instanceData:StoragePartialBuffer<{ var modelView : Mat4; }>;
		@param var radius:Float;
		@const var USING_SUB_PART:Bool = false;
		@const var MAX_SUB_PART_BUFFER_ELEMENT_COUNT:Int = 16;
		@param var subPartCount:Int;
		@param var startInstanceOffset:Int;
		@param var subPartInfos:Buffer<Vec4, MAX_SUB_PART_BUFFER_ELEMENT_COUNT>;
		@const var MAX_MATERIAL_COUNT:Int = 16;
		@param var materialCount:Int;
		@param var matIndex:Int;
		@param var matInfos:Buffer<Vec4, MAX_MATERIAL_COUNT>;
		@const var ENABLE_CULLING:Bool;
		@param var frustum:Buffer<Vec4, 6>;
		@const var ENABLE_LOD:Bool;
		@param var lodCount:Int = 1;
		@const var ENABLE_DISTANCE_CLIPPING:Bool;
		@param var maxDistance:Float = -1;
		var modelView:Mat4;
		function __init__() {
			modelView = instanceData[computeVar.globalInvocation.x].modelView;
		};
		function main() {
			var invocID = computeVar.globalInvocation.x;
			var lod:Int = 0;
			var pos = vec3(0) * modelView.mat3x4();
			var vScale = abs(vec3(1) * modelView.mat3x4() - pos);
			var scaledRadius = max(max(vScale.x, vScale.y), vScale.z);
			var toCam = camera.position - pos.xyz;
			var distToCam = length(toCam);
			var radius = radius;
			var matOffset = matIndex * lodCount;
			var lodCount = lodCount;
			if (USING_SUB_PART) {
				var id = (invocID + startInstanceOffset) * 2;
				matOffset = instanceOffsets[id];
				var subPartID = instanceOffsets[id + 1];
				var subPartInfo = subPartInfos[subPartID / 2];
				var packedID = (subPartID & 1) << 1;
				lodCount = int(subPartInfo[packedID]);
				radius = subPartInfo[packedID + 1];
			};
			scaledRadius *= radius;
			var culled = dot(scaledRadius, scaledRadius) < 1e-6;
			if (ENABLE_CULLING) {
				@unroll for (i in 0 ... 6) {
					var plane = frustum[i];
					culled = culled || plane.x * pos.x + plane.y * pos.y + plane.z * pos.z - plane.w < -scaledRadius;
				};
			};
			if (ENABLE_DISTANCE_CLIPPING) {
				culled = culled || distToCam > maxDistance + scaledRadius;
			};
			if (ENABLE_LOD) {
				var screenRatio = scaledRadius / distToCam;
				screenRatio = screenRatio * screenRatio;
				var minScreenRatioCulling = matInfos[matOffset].w;
				var culledByScreenRatio = screenRatio < minScreenRatioCulling;
				culled = culled || culledByScreenRatio;
				var lodStart = culledByScreenRatio ? lodCount : 0;
				for (i in lodStart ... lodCount) {
					var minScreenRatio = matInfos[i + matOffset].z;
					if (screenRatio > minScreenRatio) break;
					lod++;
				};
				lod = clamp(lod, 0, int(lodCount) - 1);
			};
			var matInfo = ivec4(0.0);
			if (!culled) {
				matInfo = ivec4(matInfos[lod + matOffset]);
				culled = culled || matInfo.x <= 0;
			};
			if (ENABLE_COUNT_BUFFER) {
				if (!culled) {
					var id = atomicAdd(countBuffer, 0, 1);
					commandBuffer[id * 5] = matInfo.x;
					commandBuffer[id * 5 + 1] = 1;
					commandBuffer[id * 5 + 2] = matInfo.y;
					commandBuffer[id * 5 + 3] = 0;
					commandBuffer[id * 5 + 4] = invocID;
				};
			} else {
				if (!culled) {
					commandBuffer[invocID * 5] = matInfo.x;
					commandBuffer[invocID * 5 + 1] = 1;
					commandBuffer[invocID * 5 + 2] = matInfo.y;
					commandBuffer[invocID * 5 + 3] = 0;
					commandBuffer[invocID * 5 + 4] = invocID;
				} else {
					commandBuffer[invocID * 5] = 0;
					commandBuffer[invocID * 5 + 1] = 0;
					commandBuffer[invocID * 5 + 2] = 0;
					commandBuffer[invocID * 5 + 3] = 0;
					commandBuffer[invocID * 5 + 4] = 0;
				};
			};
		};
	}) @:build(hxsl.Macros.buildShader()) @:autoBuild(hxsl.Macros.buildShader()) @:native("h3d.scene.MeshBatch") extern class ComputeIndirect extends hxsl.Shader {
	function new():Void;
	var ENABLE_COUNT_BUFFER(get, set) : Bool;
	var countBuffer(get, set) : hxsl.Types.Buffer;
	var instanceOffsets(get, set) : hxsl.Types.Buffer;
	var commandBuffer(get, set) : hxsl.Types.Buffer;
	var instanceData(get, set) : hxsl.Types.Buffer;
	var radius(get, set) : Float;
	var USING_SUB_PART(get, set) : Bool;
	var MAX_SUB_PART_BUFFER_ELEMENT_COUNT(get, set) : Int;
	var subPartCount(get, set) : Int;
	var startInstanceOffset(get, set) : Int;
	var subPartInfos(get, set) : hxsl.Types.Buffer;
	var MAX_MATERIAL_COUNT(get, set) : Int;
	var materialCount(get, set) : Int;
	var matIndex(get, set) : Int;
	var matInfos(get, set) : hxsl.Types.Buffer;
	var ENABLE_CULLING(get, set) : Bool;
	var frustum(get, set) : hxsl.Types.Buffer;
	var ENABLE_LOD(get, set) : Bool;
	var lodCount(get, set) : Int;
	var ENABLE_DISTANCE_CLIPPING(get, set) : Bool;
	var maxDistance(get, set) : Float;
	override function updateConstants(globals:hxsl.Globals):Void;
	override function getParamValue(index:Int):Dynamic;
	override function getParamFloatValue(index:Int):Float;
	override function setParamIndexValue(index:Int, val:Dynamic):Void;
	override function setParamIndexFloatValue(index:Int, val:Float):Void;
	override function clone():hxsl.Shader;
}