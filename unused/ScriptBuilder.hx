import haxe.macro.Context;
import haxe.macro.Expr;

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

class ScriptBuilder {
	public static function wrapFileInClass(scriptsDir:String):Array<Field> {
		var inClass = Context.getLocalClass().get();
		var fields = Context.getBuildFields();

		// explore folder and create those:
		var files = recursiveLoop(folder);

		for (fileName in files) {
			var name = fileName.split('/').pop().split('.').join('_');

			var valueExpr = makeType(inClass.pack, name, fileName);

			var field = {
				name: name,
				access: [APublic, AStatic, AInline],
				kind: FVar(null, valueExpr),
				pos: Context.currentPos()
			}

			fields.push(field);
		}

		trace(fields);
		return null;
	}

	static function makeType(pack:Array<String>, name:String, fileName:String) {
		trace('makeType', pack, name, fileName);
		var pos = Context.currentPos();
		var className = name.toUpperCase();

		var cdef = macro class Tmp extends haxe.io.BytesData {}
		cdef.pack = pack.copy();
		cdef.name = className;

		cdef.meta = [
			{
				name: ':file',
				params: [Context.makeExpr(fileName, pos)],
				pos: pos
			}
		];

		haxe.macro.Context.defineType(cdef);

		return {
			expr: EConst(CIdent(className)),
			pos: pos
		};
	}
}
