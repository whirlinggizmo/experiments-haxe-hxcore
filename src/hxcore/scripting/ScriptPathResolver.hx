package hxcore.scripting;

import haxe.io.Path;

class ScriptPathResolver {
	public static function classNameToPath(className:String):String {
		return StringTools.replace(className, ".", "/");
	}

	/**
	 * Derives a Haxe class name from a file path by removing extension and root prefix.
	 * e.g., "/path/to/gen/scripts/Test.cppia" with root "/path/to/gen/" -> "scripts.Test"
	 * Use classNameFromSourcePath or classNameFromCompiledPath for common cases.
	 */
	public static function classNameFromPath(filePath:String, extension:String, rootDir:String = null):String {
		var normalized = Path.normalize(filePath);
		var ext = "." + extension;
		if (!StringTools.endsWith(normalized, ext)) {
			return null;
		}
		// Remove extension
		var withoutExt = normalized.substring(0, normalized.length - ext.length);
		// If root provided, make path relative to it
		var relativePath = withoutExt;
		if (rootDir != null && rootDir.length > 0) {
			var normalizedRoot = Path.addTrailingSlash(Path.normalize(rootDir));
			if (StringTools.startsWith(withoutExt, normalizedRoot)) {
				relativePath = withoutExt.substring(normalizedRoot.length);
			}
		}
		// Convert path separators to dots
		return StringTools.replace(relativePath, "/", ".");
	}

	/**
	 * Derives a Haxe class name from a compiled script file path.
	 * e.g., "/path/to/gen/scripts/Test.cppia" -> "scripts.Test"
	 */
	public static function classNameFromCompiledPath(compiledPath:String, extension:String = "cppia", outputRoot:String = null):String {
		return classNameFromPath(compiledPath, extension, outputRoot);
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

	/**
	 * Derives a Haxe class name from a source script file path.
	 * e.g., "/path/to/scripts/Foo.hx" -> "scripts.Foo"
	 */
	public static function classNameFromSourcePath(sourcePath:String, sourceRoot:String = null):String {
		return classNameFromPath(sourcePath, "hx", sourceRoot);
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
