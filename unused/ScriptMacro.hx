import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.macro.TypePath;

class ScriptMacro {
	public static function makeExtend(baseClassName:String, targetClassName:String) {
		// Parse fully qualified class names into TypePaths
		var baseClassPath = parseTypePath(baseClassName);
		var targetClassPath = parseTypePath(targetClassName);

		// Register a function to run after typing is complete
		Context.onAfterTyping(function(types) {
			for (t in types) {
				var tType = t.get();
				if (TypeTools.fullName(tType) == targetClassName) {
					switch (tType) {
						case TClassDecl(classDecl):
							// Check if the class already extends another class
							if (classDecl.superClass != null) {
								Context.error('Class ' + targetClassName + ' already extends ' + TypeTools.toString(classDecl.superClass), classDecl.pos);
							} else {
								// Set the superClass to the base class
								classDecl.superClass = {
									tpackage: baseClassPath.pack,
									tname: baseClassPath.name,
									tparams: [],
									tsub: null
								};
							}
						default:
							// Do nothing
					}
				}
			}
		});
	}

	// Helper function to parse fully qualified class names
	private static function parseTypePath(fullyQualifiedName:String):TypePath {
		var parts = fullyQualifiedName.split('.');
		return {
			pack: parts.slice(0, parts.length - 1),
			name: parts[parts.length - 1],
			params: []
		};
	}
}
