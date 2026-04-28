package hxcore.scripting;

import haxe.io.Path;

class ScriptPathResolver {
	public static function classNameToPath(className:String):String {
		return StringTools.replace(className, ".", "/");
	}

	public static function compiledScriptRelativePath(className:String, extension:String = "cppia"):String {
		return classNameToPath(className) + "." + extension;
	}

	public static function compiledScriptPath(scriptOutputRoot:String, className:String, extension:String = "cppia"):String {
		var outputRoot = Path.addTrailingSlash(Path.normalize(scriptOutputRoot));
		return Path.normalize(Path.join([outputRoot, compiledScriptRelativePath(className, extension)]));
	}

	public static function sourceScriptPath(rootDir:String, className:String):String {
		var root = Path.addTrailingSlash(Path.normalize(rootDir));
		return Path.join([root, classNameToPath(className) + ".hx"]);
	}

	public static function generatedClassName(className:String, generatedNamespace:String):String {
		return generatedNamespace != null && generatedNamespace.length > 0 ? generatedNamespace + "." + className : className;
	}

	public static function exportClassesInfoPath(scriptSourceRoot:String):String {
		return Path.join([Path.normalize(scriptSourceRoot), "export_classes.filtered.info"]);
	}

	public static function sourceRootParent(scriptSourceRoot:String):String {
		return Path.directory(Path.removeTrailingSlashes(Path.normalize(scriptSourceRoot)));
	}

	public static function sourceRootPackage(scriptSourceRoot:String):String {
		var normalized = Path.removeTrailingSlashes(Path.normalize(scriptSourceRoot));
		var parts = normalized.split("/");
		return parts[parts.length - 1];
	}

	public static function relativeSourcePathWithinRoot(scriptSourceRoot:String, className:String):String {
		var rootPackage = sourceRootPackage(scriptSourceRoot);
		var classNameParts = className.split(".");
		var classNameTopLevelPackage = classNameParts.shift();
		if (classNameTopLevelPackage != rootPackage) {
			return null;
		}
		return "./" + classNameParts.join("/") + ".hx";
	}
}
