package h3d.scene.pbr;

@:src({
		@const var samplesBits:Int;
		function _reversebits(i:Int):Int {
			var r = (i << 16) | (i >>> 16);
			r = ((r & 0x00ff00ff) << 8) | ((r & 0xff00ff00) >>> 8);
			r = ((r & 0x0f0f0f0f) << 4) | ((r & 0xf0f0f0f0) >>> 4);
			r = ((r & 0x33333333) << 2) | ((r & 0xcccccccc) >>> 2);
			r = ((r & 0x55555555) << 1) | ((r & 0xaaaaaaaa) >>> 1);
			return r;
		};
		function hammersley(i:Int, max:Int):Vec2 {
			var ri = _reversebits(i) * 2.3283064365386963e-10;
			return vec2(float(i) / float(max), ri);
		};
		function importanceSampleGGX(roughness:Float, p:Vec2, n:Vec3):Vec3 {
			var a = roughness * roughness;
			var phi = 2 * PI * p.x;
			var cosT = sqrt((1 - p.y) / (1 + (a * a - 1) * p.y)).min(1.);
			var sinT = sqrt(1 - cosT * cosT);
			var ltan = vec3(sinT * cos(phi), sinT * sin(phi), cosT);
			var up = abs(n.z) < 0.999 ? vec3(0, 0, 1) : vec3(1, 0, 0);
			var tanX = normalize(cross(up, n));
			var tanY = normalize(cross(n, tanX));
			return (tanX * ltan.x + tanY * ltan.y + n * ltan.z).normalize();
		};
	}) @:build(hxsl.Macros.buildShader()) @:autoBuild(hxsl.Macros.buildShader()) @:native("h3d.scene.pbr.Environment") extern class IrradBase extends h3d.shader.ScreenShader {
	function new():Void;
	var samplesBits(get, set) : Int;
	override function updateConstants(globals:hxsl.Globals):Void;
	override function getParamValue(index:Int):Dynamic;
	override function getParamFloatValue(index:Int):Float;
	override function clone():hxsl.Shader;
}

@:src({
		@param var faceMatrix:Mat3;
		@param var envMap:SamplerCube;
		@const var isSpecular:Bool;
		@const var isSRGB:Bool;
		@param var roughness:Float;
		@param var cubeSize:Float;
		@param var cubeScaleFactor:Float;
		@param var hdrMax:Float;
		function cosineWeightedSampling(p:Vec2, n:Vec3):Vec3 {
			var sq = sqrt(1 - p.x);
			var alpha = 2 * PI * p.y;
			var ltan = vec3(sq * cos(alpha), sq * sin(alpha), sqrt(p.x));
			var up = abs(n.z) < 0.999 ? vec3(0, 0, 1) : vec3(1, 0, 0);
			var tanX = normalize(cross(up, n));
			var tanY = normalize(cross(n, tanX));
			return (tanX * ltan.x + tanY * ltan.y + n * ltan.z).normalize();
		};
		function getNormal():Vec3 {
			var d = input.uv * 2. - 1.;
			if (isSpecular) {
				d += cubeScaleFactor * (d * d * d);
			};
			return (vec3(d, 1.) * faceMatrix).normalize();
		};
		function gammaCorrect(color:Vec3):Vec3 {
			return isSRGB ? color : color.pow(vec3(2.2));
		};
		function fragment() {
			var color = vec3(0.);
			var n = getNormal();
			var totalWeight = 1e-10;
			var numSamples = 1 << samplesBits;
			for (i in 0 ... numSamples) {
				var p = hammersley(i, numSamples);
				var l:Vec3;
				if (isSpecular) {
					var h = importanceSampleGGX(roughness, p, n);
					var v = n;
					l = reflect(-v, h).normalize();
				} else {
					l = cosineWeightedSampling(p, n);
				};
				var amount = n.dot(l).saturate();
				if (amount > 0) {
					var envColor = gammaCorrect(min(envMap.get(l).rgb, hdrMax));
					color += envColor * amount;
					totalWeight += amount;
				};
			};
			output.color = vec4(color / totalWeight, 1.);
		};
	}) @:build(hxsl.Macros.buildShader()) @:autoBuild(hxsl.Macros.buildShader()) @:native("h3d.scene.pbr.Environment") extern class IrradShader extends h3d.scene.pbr.Environment.IrradBase {
	function new():Void;
	var faceMatrix(get, set) : hxsl.Types.Matrix;
	var envMap(get, set) : hxsl.Types.Texture;
	var isSpecular(get, set) : Bool;
	var isSRGB(get, set) : Bool;
	var roughness(get, set) : Float;
	var cubeSize(get, set) : Float;
	var cubeScaleFactor(get, set) : Float;
	var hdrMax(get, set) : Float;
	override function updateConstants(globals:hxsl.Globals):Void;
	override function getParamValue(index:Int):Dynamic;
	override function getParamFloatValue(index:Int):Float;
	override function clone():hxsl.Shader;
}

@:src({
		function GGX(NdotV:Float, roughness:Float):Float {
			var k = (roughness * roughness) * 0.5;
			return NdotV / (NdotV * (1.0 - k) + k);
		};
		function G_Smith(roughness:Float, nDotV:Float, nDotL:Float):Float {
			return GGX(nDotL, roughness) * GGX(nDotV, roughness);
		};
		function fragment() {
			var roughness = input.uv.x;
			var NoV = input.uv.y;
			var v = vec3(sqrt(1.0 - NoV * NoV), 0., NoV);
			var n = vec3(0, 0, 1.);
			var numSamples = 1 << samplesBits;
			var a = 0., b = 0.;
			for (i in 0 ... numSamples) {
				var xi = hammersley(i, numSamples);
				var h = importanceSampleGGX(roughness, xi, n);
				var l = reflect(-v, h);
				var NoL = saturate(dot(n, l));
				var NoH = saturate(dot(n, h));
				var VoH = saturate(dot(v, h));
				if (NoL > 0) {
					var g = G_Smith(roughness, NoV, NoL);
					var gvis = g * VoH / (NoH * NoV);
					var fresnel = pow(1 - VoH, 5.);
					a += (1 - fresnel) * gvis;
					b += fresnel * gvis;
				};
			};
			output.color = vec4(a / numSamples, b / numSamples, 0, 1);
		};
	}) @:build(hxsl.Macros.buildShader()) @:autoBuild(hxsl.Macros.buildShader()) @:native("h3d.scene.pbr.Environment") extern class IrradLut extends h3d.scene.pbr.Environment.IrradBase {
	function new():Void;
	override function updateConstants(globals:hxsl.Globals):Void;
	override function getParamValue(index:Int):Dynamic;
	override function getParamFloatValue(index:Int):Float;
	override function clone():hxsl.Shader;
}

@:src({
		@param var texture:Sampler2D;
		@param var faceMatrix:Mat3;
		@param var threshold:Float;
		@param var aboveThresholdScale:Float;
		function getNormal():Vec3 {
			var d = input.uv * 2. - 1.;
			return (vec3(d, 1.) * faceMatrix).normalize();
		};
		function fragment() {
			var n = getNormal();
			var uv = vec2(atan(n.y, n.x), asin(-n.z));
			uv *= vec2(0.1591, 0.3183);
			uv += 0.5;
			pixelColor = texture.get(uv);
			if (max(max(pixelColor.r, pixelColor.g), pixelColor.b) > threshold) pixelColor *= aboveThresholdScale;
		};
	}) @:build(hxsl.Macros.buildShader()) @:autoBuild(hxsl.Macros.buildShader()) @:native("h3d.scene.pbr.Environment") extern class PanoramaToCube extends h3d.shader.ScreenShader {
	function new():Void;
	var texture(get, set) : hxsl.Types.Texture;
	var faceMatrix(get, set) : hxsl.Types.Matrix;
	var threshold(get, set) : Float;
	var aboveThresholdScale(get, set) : Float;
	override function updateConstants(globals:hxsl.Globals):Void;
	override function getParamValue(index:Int):Dynamic;
	override function getParamFloatValue(index:Int):Float;
	override function clone():hxsl.Shader;
}

@:src({
		@param var source:SamplerCube;
		function fragment() {
			var fovX = PI * 2;
			var fovY = PI;
			var hOffset = (2.0 * PI - fovX) * 0.5;
			var vOffset = (PI - fovY) * 0.5;
			var hAngle = hOffset + calculatedUV.x * fovX;
			var vAngle = vOffset + calculatedUV.y * fovY;
			var n = vec3(0);
			n.x = sin(vAngle) * sin(hAngle);
			n.y = cos(vAngle);
			n.z = sin(vAngle) * cos(hAngle);
			n = n.normalize();
			pixelColor = vec4(source.get(n).rgb, 1.0);
			pixelColor = vec4(1, 0, 0, 1);
		};
	}) @:build(hxsl.Macros.buildShader()) @:autoBuild(hxsl.Macros.buildShader()) @:native("h3d.scene.pbr.Environment") extern class CubeToPanorama extends h3d.shader.ScreenShader {
	function new():Void;
	var source(get, set) : hxsl.Types.Texture;
	override function updateConstants(globals:hxsl.Globals):Void;
	override function getParamValue(index:Int):Dynamic;
	override function getParamFloatValue(index:Int):Float;
	override function clone():hxsl.Shader;
}

@:native("h3d.scene.pbr.Environment") extern class Environment {
	function new(src:h3d.mat.Texture, ?diffSize:Int, ?specSize:Int, ?sampleBits:Int):Void;
	var sampleBits : Int;
	var diffSize : Int;
	var specSize : Int;
	var specLevels : Int;
	var ignoredSpecLevels : Int;
	var hdrMax : Float;
	var source : h3d.mat.Texture;
	var env(get, null) : h3d.mat.Texture;
	var lut(get, never) : h3d.mat.Texture;
	var diffuse : h3d.mat.Texture;
	var specular : h3d.mat.Texture;
	var power : Float;
	var rotation : Float;
	private function get_lut():h3d.mat.Texture;
	private function get_env():h3d.mat.Texture;
	function dispose():Void;
	function compute():Void;
	static function getDefaultLUT():h3d.mat.Texture;
	static function equiToCube(source:h3d.mat.Texture, ?threshold:Float, ?scale:Float):h3d.mat.Texture;
	static function getDefault():h3d.scene.pbr.Environment;
}