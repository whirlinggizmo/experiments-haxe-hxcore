package core.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;

class GenerateExterns {
	macro public static function loadPackage(packageName:String):Expr {
		// run haxelib to get the libpath
        var libName = 'heaps';
		var haxelibExe = "haxelib";
		var haxelibArgs = ["libpath", libName];
		Sys.println("Running " + haxelibExe + " " + haxelibArgs.join(" "));
		var result = new sys.io.Process(haxelibExe, haxelibArgs);
		var output = result.stdout.readAll().toString();
		output = StringTools.trim(output);
		var libPath = StringTools.trim(output);
		Sys.println("Result: " + output);

		var libPaths = [];
		libPaths.push(libPath);

		Compiler.include(packageName, true, null, libPaths, true);
        var types = Context.getModule(packageName);
		for (t in types) {
			trace('Found type: ' + t);
		}

		return macro {}; // Macro must return an expression
	}

	public static function run(libName:String = "", packageName:String = "hxd") {
		var classes = [];

		// run haxelib to get the libpath
		var haxelibExe = "haxelib";
		var haxelibArgs = ["libpath", libName];
		Sys.println("Running " + haxelibExe + " " + haxelibArgs.join(" "));
		var result = new sys.io.Process(haxelibExe, haxelibArgs);
		var output = result.stdout.readAll().toString();
		output = StringTools.trim(output);
		var libPath = StringTools.trim(output);
		Sys.println("Result: " + output);

		var libPaths = [];
		libPaths.push(libPath);

		Compiler.include(packageName, true, null, libPaths, true);

		var module = Context.getModule(packageName);
		if (module == null) {
			Sys.println("Could not find package: " + packageName);
			return;
		}

		return;

		/*
			if (libName != "") {
				// run haxelib to get the libpath
				var haxelibExe = "haxelib";
				var haxelibArgs = ["libpath", libName];
				Sys.println("Running " + haxelibExe + " " + haxelibArgs.join(" "));
				var result = new sys.io.Process(haxelibExe, haxelibArgs);
				var output = result.stdout.readAll().toString();    
				output = StringTools.trim(output);
				var libPath = StringTools.trim(output);
				Sys.println("Result: " + output);

				
				Sys.println("Scanning " + libPath);
				scanDirectory(libPath, packageName, classes);

				//    var hxdPath = '/home/rknopf/toolchains/haxe/haxelib/heaps/git/';
				//    if (FileSystem.exists(hxdPath) && FileSystem.isDirectory(hxdPath)) {
				//        scanDirectory(hxdPath, packageName, classes);
				//    }
				// }

				var output = haxe.Json.stringify(classes, null, "  ");
				File.saveContent("hxd_package_scan_result.json", output);
				Sys.println("Package scan complete. Results saved to hxd_package_scan_result.json");
			} else {
				Sys.println("Please provide a valid haxelib name.");
			}
		 */
	}
	/*
		private static function scanDirectory(dir:String, currentPackage:String, classes:Array<Dynamic>) {
			for (file in FileSystem.readDirectory(dir)) {
				var path = dir + "/" + file;
				if (FileSystem.isDirectory(path)) {
					scanDirectory(path, currentPackage + "." + file, classes);
				} else if (StringTools.endsWith(file, ".hx") && StringTools.endsWith(file, ".hx")) {
					var className = file.substr(0, file.length - 3);
					var fullClassName = currentPackage + "." + className;
					var content = File.getContent(path);
					var fields = extractFields(content);

					// get the field type
					var classFields = [];
					for (i in fields) {
						var fieldType = haxe.macro.Context.typeof(i);
						classFields.push({
							name: fields[i],
							type: fieldType
						});
					}
					classes.push({
						name: fullClassName,
						fields: classFields
					});
				}
			}
		}
	 */
	/*
		private static function extractFields(content:String):Array<String> {
			var fieldRegex = ~/\bfunction\s+(\w+)/g;
			var fields = [];
			while (fieldRegex.match(content)) {
				fields.push(fieldRegex.matched(1));
				content = fieldRegex.matchedRight();
			}
			return fields;
		}
	 */
}
#end
