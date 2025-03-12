package core.macros;

/**
 * @description
 * This macro scans the project for types, and generates externs for them... in theory.  
 * 
 * The intent was to create externs for libraries like heaps( h3d, h2d, hxd, etc), so the externs would be used during development
 * and compilation of the 'scripts', so they didn't create two copies of the same code.
 * 
 * In reality, it's not done, doesn't really work, and honestly is one of the most hacky things I've ever done.
 * Instead, we use the --exclude macro in the script build hxml, removing the libraries from the compilation, which is ultimately what we want.
 * 
 * Should future me see this:  Shame on you.  This is a mess and you should be ashamed of yourself. 
 * 
 * TODO:  Look into how cppia uses the export_classes.info file and adapt it for removal of externs?
 */

import haxe.macro.Type.ClassField;
import haxe.macro.Type.ModuleType;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.AbstractType;
import haxe.macro.Type.DefType;
import haxe.macro.Type.EnumType;
import haxe.macro.Context;
import haxe.macro.Expr;
import hxd.Math;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

var outputText = "";

function deleteDirectoryRecursively(path:String):Void {
	if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path)) {
		var entries = sys.FileSystem.readDirectory(path);
		for (entry in entries) {
			if (sys.FileSystem.isDirectory(path + '/' + entry)) {
				deleteDirectoryRecursively(path + '/' + entry);
				sys.FileSystem.deleteDirectory(path + '/' + entry);
			} else {
				sys.FileSystem.deleteFile(path + '/' + entry);
			}
		}
	}
}

function fileExists(rootDirectory:String, path:String, fileName:String):Bool {
	return sys.FileSystem.exists(haxe.io.Path.join([rootDirectory, path, fileName]));
}

function writeln(line:String):Void {
	outputText += line + "\n";
}

function write(line:String):Void {
	outputText += line;
}

function saveOutput(rootDirectory:String, path:String, fileName:String):Void {
	// write to file
	// make sure the directory exists
	var outputDir = haxe.io.Path.join([rootDirectory, path]);
	if (!FileSystem.exists(outputDir)) {
		FileSystem.createDirectory(outputDir);
	}
	var outputPath = haxe.io.Path.join([outputDir, fileName]);

	// Sys.println("Writing to: " + outputPath);
	outputText = outputText + "\n\n";
	if (!sys.FileSystem.exists(outputPath)) {
		File.saveContent(outputPath, outputText);
	} else {
		// file already exists, append
		var f = File.append(outputPath, false);
		f.writeString(outputText);
		f.close();
	}
}

function writeClassFields(fields:Array<ClassField>):Void {
	for (field in fields) {
		if (field.isPublic) {
			switch (field.type) {
				// class properties
				case TInst(t, params):
					write("\t" + "public var " + field.name );
					if (t.get().name == "Int") {
						write(": Int");
					} else if (t.get().name == "Float") {
						write(": Float");
					} else if (t.get().name == "Bool") {
						write(": Bool");
					} else if (t.get().name == "String") {
						write(": String");
					} else if (t.get().name == "Void") {
						write(": Void");
					} else if (t.get().name == "Null") {
						//write(": Null");
					} else {
						write(': Dynamic /* ${t.get().module} */');
					}
					writeln(";");
				case TAbstract(t, params):
					write("\t" + "public var " + field.name );
					if (t.get().name == "Int") {
						write(" :Int");
					} else if (t.get().name == "Float") {
						write(": Float");
					} else if (t.get().name == "Bool") {
						write(": Bool");
					} else if (t.get().name == "String") {
						write(": String");
					} else if (t.get().name == "Void") {
						write(": Void");
					} else if (t.get().name == "Null") {
						write(": Dynamic");
					} else {
						write(': Dynamic /* ${t.get().module} */');
					}
					writeln(";");
				case TType(t, params):
					write("\t" + "public var " + field.name);
					if (t.get().name == "Int") {
						write(": Int");
					} else if (t.get().name == "Float") {
						write(": Float");
					} else if (t.get().name == "Bool") {
						write(": Bool");
					} else if (t.get().name == "String") {
						write(": String");
					} else if (t.get().name == "Void") {
						//write(" : Void");
					} else if (t.get().name == "Null") {
						//write(" Void");
					} else {
						write(' :Dynamic /* ${t.get().module} */');
					}
					writeln(";");
				case TEnum(t, params):
					write("\t" + "public var " + field.name);
					if (t.get().name == "Int") {
						write(": Int");
					} else if (t.get().name == "Float") {
						write(": Float");
					} else if (t.get().name == "Bool") {
						write(": Bool");
					} else if (t.get().name == "String") {
						write(": String");
					} else if (t.get().name == "Void") {
						write(": Void");
					} else if (t.get().name == "Null") {
						//write(": Void");
					} else {
						write(': Dynamic /* ${t.get().module} */');
					}
					writeln(";");
				// class methods
				case TFun(args, returnType):
					var methodName = field.name;

					write("\t" + "public function " + methodName + "(");
					for (arg in args) {
						//var varName = arg.name;
						switch (arg.t) {
							case TAbstract(t, params):





								switch (t.get().name) {
									case "Void":
										write(arg.name);
										write("::: ");
										write(t.toString());
									case "Null":
										if (arg.opt) {
											write('?');
										}
										write(arg.name);
										write(": ");
										write("Dynamic");

									case _:
										write(arg.name);
										write(": ");
										//write(t.toString());
										write("Dynamic");

										//write(t.get().module);
								}

							case TDynamic(t):
								write(arg.name);
								write(": ");
								write("Dynamic");
							case TInst(t, params):
								switch (t.get().name) {
									case "Int":
										write(arg.name);
										if (arg.name.length > 0) write(": ");
										write("Int");
									case "Float":
										write(arg.name);
										if (arg.name.length > 0) write(": ");
										write("Float");
									case "Bool":
										write(arg.name);
										if (arg.name.length > 0) write(": ");
										write("Bool");
									case "String":
										write(arg.name);
										if (arg.name.length > 0) write(": ");
										write("String");
									case "Void":
										// write("VOID");
									case "Null":
										// write("NULL");
									case "Array":
										write(arg.name);
										if (arg.name.length > 0) write(": ");
										write("Dynamic");
										/*
										for (param in params) {
											switch (param) {
												case TInst(t, params):
													write('<${t.toString()}>');
												case TType(t, params):
													write('<${t.toString()}>');
												case TAbstract(t, params):
													write('<${t.toString()}>');
												case TDynamic(t):
													write(' <Dynamic>');
												case _:	
													write(' <Dynamic>');
											}
										}
											*/
									case _:
										write(arg.name);
										if (arg.name.length > 0) write(": ");
										write('Dynamic /* ${t.get().module} */');
										//write('${t.toString()} ');
								}
							case _:
								write(arg.name);
								if (arg.name.length > 0) write(": ");
								write('Dynamic /* ${arg.t} */');
						}
						if (arg != args[args.length - 1]) {
							write(", ");
						}
					}
					write(")");
					switch (returnType) {
						case TAbstract(t, params):
							switch (t.get().name) {
								case "Int":
									write(": Int");
								case "Float":
									write(": Float");
								case "Bool":
									write(": Bool");
								case "String":
									write(": String");
								case "Void":
									write(": Void");
								//case "Null":
								//	 write(" NOT EXPLICIT");
								case _: write(': Dynamic /* ${t.get().module} */');
							}

						case TDynamic(t):
							write(': Dynamic');

						case TInst(t, params):
							switch (t.get().name) {
								case "Int":
									write(": Int");
								case "Float":
									write(": Float");
								case "Bool":
									write(": Bool");
								case "String":
									write(": String");
								case "Void":
									write(": Void");
								//case "Null":
									// write(" Void");
								case _: write(': Dynamic /* ${t.get().module} */');
							}
						case _:
							write(': Dynamic /* ${returnType} */');
					}
					writeln(";");

				case _: // ignore non-functions for now.  TODO:  properties
			}
		}
	}
}

function writeAbstract(rootDirectory:String, abstractType:AbstractType):Void {
	outputText = "";

	if (abstractType.isPrivate) {
		return;
	}

	// package
	var packageParts = abstractType.module.split(".");
	var moduleFileName = packageParts.pop() + ".hx";
	var outputDir = haxe.io.Path.join(packageParts);

	// if the module already exists, don't write the package name (we append when we save the output)
	if (!fileExists(rootDirectory, outputDir, moduleFileName)) {
		writeln("package " + packageParts.join(".") + ";");
		writeln("");
	}

	// native extern
	// writeln("@:native(\"" + abstractType.module + "." + abstractType.name + "\")");

	// mark it as extern
	// write("extern ");

	var t = abstractType.type;

	switch (t) {
		case TAbstract(t, params):
			write("typedef " + abstractType.name + " = " + t.toString() + ";");
		case TType(t, params):
			write("typedef " + abstractType.name + " = " + t.toString() + ";");
		case TEnum(t, params):
			write("typedef " + abstractType.name + " = " + t.toString() + ";");
		case TDynamic(t):
			write("typedef " + abstractType.name + " = Dynamic;");
		case TInst(t, params):
			write("typedef " + abstractType.name + " = " + t.toString() + ";");
		case _:
			write("typedef " + abstractType.name + " = Dynamic;");
	}

	/*


		writeln("typedef " + abstractType.name + " = Dynamic;");

		// abstract declaration
		write("abstract class " + abstractType.name);
		// begin abstract body
		writeln(" {");

		// abstract fields
		var implFieldsRef = abstractType.impl?.get().fields;
		if (implFieldsRef != null) {
			var implFields = implFieldsRef.get();
			writeClassFields(implFields);
			for (field in implFields) {
				trace("Found impl field: " + field.name);
			}
		}
		trace ("implType: " + abstractType.type);

		// end abstract body
		writeln("}");
	 */
	// write to file

	saveOutput(rootDirectory, outputDir, moduleFileName);
}

function writeClass(rootDirectory:String, classType:ClassType):Void {
	outputText = "";

	// package
	var packageParts = classType.module.split(".");
	var moduleFileName = packageParts.pop() + ".hx";
	var outputDir = haxe.io.Path.join(packageParts);

	if (classType.isPrivate) {
		return;
	}

	// if the module already exists, don't write the package name (we append when we save the output)
	if (!fileExists(rootDirectory, outputDir, moduleFileName)) {
		writeln("package " + packageParts.join(".") + ";");
		writeln("");
	}

	// native extern
	writeln("@:native(\"" + classType.module + "\")");

	// mark it as extern
	write("extern ");

	// class declaration
	if (classType.isInterface) {
		write("interface ");
	} else {
		write("class ");
	}

	write(classType.name);
	// add superclass if it exists
	if (classType.superClass != null) {
		write(" extends " + classType.superClass.t.get().module);
	}
	// begin class body
	writeln(" {");

	// constructor
	if (classType.constructor != null && classType.constructor.get().isPublic) {
		write("\t" + "public function " + classType.constructor.get().name + "(");
		var params = classType.constructor.get().params;
		for (param in params) {
			write(param.name);
			write(" : ");
			switch (param.t) {
				case TInst(t, params):
					if (t.get().name == "Int") {
						write(" Int");
					} else if (t.get().name == "Float") {
						write(" Float");
					} else if (t.get().name == "Bool") {
						write(" Bool");
					} else if (t.get().name == "String") {
						write(" String");
					} else if (t.get().name == "Void") {
						write(" Void");
					} else if (t.get().name == "Null") {
						write(" Void");
					} else {
						write(' Dynamic /* ${t.get().name} */');
					}
				case _:
					write(' Dynamic /* ${param.t} */');
			}

			if (param != params[params.length - 1]) {
				write(", ");
			}
		}
		writeln(");");
	}
	// class fields

	var fields = classType.fields.get();

	writeClassFields(fields);
	writeln("}");
	// end class body
	writeln("");

	// write to file
	saveOutput(rootDirectory, outputDir, moduleFileName);
}

function writeEnum(rootDirectory:String, enumType:EnumType):Void {
	outputText = "";

	if (enumType.isPrivate) {
		return;
	}
	// package
	var packageParts = enumType.module.split(".");
	var moduleFileName = packageParts.pop() + ".hx";
	var outputDir = haxe.io.Path.join(packageParts);

	// if the module already exists, don't write the package name (we append when we save the output)
	if (!fileExists(rootDirectory, outputDir, moduleFileName)) {
		writeln("package " + packageParts.join(".") + ";");
		writeln("");
	}

	// native extern
	writeln("@:native(\"" + enumType.module + "." + enumType.name + "\")");

	// mark it as extern
	write("extern ");

	// enum declaration
	writeln("enum " + enumType.name + " {");
	// enum fields
	var fields = enumType.names;
	for (field in fields) {
		writeln("\t" + field + ";");
	}
	writeln("}");

	saveOutput(rootDirectory, outputDir, moduleFileName);
}

function writeDef(rootDirectory:String, defType:DefType):Void {
	outputText = "";

	if (defType.isPrivate) {
		return;
	}
	// package
	var packageParts = defType.module.split(".");
	var moduleFileName = packageParts.pop() + ".hx";
	var outputDir = haxe.io.Path.join(packageParts);

	// if the module already exists, don't write the package name (we append when we save the output)
	if (!fileExists(rootDirectory, outputDir, moduleFileName)) {
		writeln("package " + packageParts.join(".") + ";");
		writeln("");
	}

	var t = defType.type;

	switch (t) {
		case TAbstract(t, params):
			write("typedef " + defType.name + " = " + t.toString() + ";");
		case TType(t, params):
			write("typedef " + defType.name + " = " + t.toString() + ";");
		case TEnum(t, params):
			write("typedef " + defType.name + " = " + t.toString() + ";");
		case TDynamic(t):
			write("typedef " + defType.name + " = Dynamic;");
		case TInst(t, params):
			write("typedef " + defType.name + " = " + t.toString() + ";");
		case _:
			write("typedef " + defType.name + " = Dynamic;");
	}

	// writeln("}");

	saveOutput(rootDirectory, outputDir, moduleFileName);
}

class ExternGenerator {
	macro public static function generate(exportDir:String, packageName:String):Expr {
		// clean the export directory
		var moduleDir = haxe.io.Path.join([exportDir, packageName]);
		if (sys.FileSystem.exists(moduleDir)) {
			deleteDirectoryRecursively(moduleDir);
		}

		Context.onAfterTyping((moduleTypes:Array<ModuleType>) -> {
			// trace("Found module: " + moduleType);
			var classTypes = new Map<String, ClassType>();
			var abstractTypes = new Map<String, AbstractType>();
			var defTypes = new Map<String, DefType>();
			var enumTypes = new Map<String, EnumType>();

			for (moduleType in moduleTypes) {
				switch (moduleType) {
					case TClassDecl(classTypeRef):
						var pack = classTypeRef.get().pack;
						if (pack.length > 0 && pack[0] == packageName) {
							classTypes.set(classTypeRef.get().module + "::" + classTypeRef.get().name, classTypeRef.get());
						}
					case TTypeDecl(typeRef):
						var pack = typeRef.get().pack;
						if (pack.length > 0 && pack[0] == packageName) {
							defTypes.set(typeRef.get().module + "::" + typeRef.get().name, typeRef.get());
							trace('Found DefType: ${typeRef.get().name}');
						}
					case TAbstract(abstractTypeRef):
						var pack = abstractTypeRef.get().pack;
						if (pack.length > 0 && pack[0] == packageName) {
							abstractTypes.set(abstractTypeRef.get().module + "::" + abstractTypeRef.get().name, abstractTypeRef.get());
							// trace('Found AbstractType: ${abstractTypeRef.get().name}');
						}
					case TEnumDecl(enumTypeRef):
						var pack = enumTypeRef.get().pack;
						if (pack.length > 0 && pack[0] == packageName) {
							enumTypes.set(enumTypeRef.get().module + "::" + enumTypeRef.get().name, enumTypeRef.get());
							// trace('Found EnumType: ${enumTypeRef.get().name}');
						}
						// case _: // Ignore other types
				}
			}

			for (classType in classTypes) {
				writeClass(exportDir, classType);
			}

			for (abstractType in abstractTypes) {
				writeAbstract(exportDir, abstractType);
			}

			for (defType in defTypes) {
				writeDef(exportDir, defType);
			}

			for (enumType in enumTypes) {
				writeEnum(exportDir, enumType);
			}
		});
		return macro {};
	}

	macro public static function scanLib(packageName:String):Expr {
		var modules = Context.getModule(packageName);

		for (module in modules) {
			trace("Found module: " + module);
		}

		return macro {};
	}
}
