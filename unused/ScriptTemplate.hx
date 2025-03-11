import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;

function recursiveLoop(directory:String = "path/to/"):Array<String> {
	var files:Array<String> = new Array<String>();

	if (sys.FileSystem.exists(directory)) {
		trace("directory found: " + directory);
		for (file in sys.FileSystem.readDirectory(directory)) {
			var path = haxe.io.Path.join([directory, file]);
			if (!sys.FileSystem.isDirectory(path)) {
				trace("file found: " + path);
				// do something with file
				files.push(path);
			} else {
				var directory = haxe.io.Path.addTrailingSlash(path);
				trace("directory found: " + directory);
				recursiveLoop(directory);
			}
		}
	} else {
		trace('"$directory" does not exists');
	}

	return files;
}

class ScriptTemplate {
	public static function wrapFileInClass(scriptsDir:String):Array<Field> {
		var files = recursiveLoop(scriptsDir);
		trace(files);
		var k = Context.getLocalClass();
		trace(k);
		// get the current fields of the class
		var fields:Array<Field> = Context.getBuildFields();

		// get the path of the current current class file, e.g. "src/path/to/MyClassName.hx"
		var posInfos = Context.getPosInfos(Context.currentPos());
		var directory = Path.directory(posInfos.file);

		// get the current class information.
		var ref:ClassType = Context.getLocalClass().get();
		// path to the template. syntax: "MyClassName.template"
		var filePath:String = Path.join([directory, ref.name + ".template"]);

		// detect if template file exists
		if (FileSystem.exists(filePath)) {
			// get the file content of the template
			var fileContent:String = File.getContent(filePath);

			// add a static field called "TEMPLATE" to the current fields of the class
			fields.push({
				name: "TEMPLATE",
				access: [Access.AStatic, Access.APublic],
				kind: FieldType.FVar(macro :String, macro $v{fileContent}),
				pos: Context.currentPos(),
				doc: "auto-generated from " + filePath,
			});
		}

		return fields;
	}
}
