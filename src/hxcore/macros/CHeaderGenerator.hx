package hxcore.macros;

#if (haxe_ver < 4.0) #error "Haxe 4.0 required" #end

#if macro

import haxe.macro.Context;
import sys.io.File;
import haxe.macro.Expr;

class CHeaderGenerator {
	public static function generate():Array<Field> {
		// Retrieve all build fields for the class
		var fields:Array<Field> = Context.getBuildFields();
		var buffer = new StringBuf();

		// Get the current class name for name mangling.
		// Context.getLocalType() should return a TInst for a class.
		var localType = Context.getLocalType();
		var className = switch (localType) {
			case TInst(c, _): c.get().name;
			default: "Unknown";
		};

		buffer.add("#pragma once\n\n");
		buffer.add('extern "C" {\n');

		for (field in fields) {
			// Check for the @:cExport metadata.
			if (field.meta != null && field.meta.filter(function(m) return m.name == ":cExport").length > 0) {
				// Ignore non-public fields.
				if (field.access != null && field.access.filter(function(a) return a == Access.APublic).length == 0) {
					continue;
				}
				switch (field.kind) {
					case FFun(f):
						// Prefix the function name with the class name.
						var originalName = field.name;
						var mangledName = className + "_" + originalName;
						
            // Check if an @:export metadata is already present.
						if (field.meta.filter(function(m) return m.name == "export").length == 0) {
							// Add export metadata: ideally, you want the equivalent of @:export("mangledName").
							// The metadata is represented as an object with name, params and pos.
							field.meta.push({name: "export", params: [macro $v{mangledName}], pos: field.pos});
              trace("Added @:export metadata: " + mangledName);
            }

						var args = f.args.map(function(a) {
							var argType = if (a.type != null) typeToC(a.type) else "void*";
							return argType + " " + a.name;
						});
						var ret = if (f.ret != null) typeToC(f.ret) else "void";
						buffer.add('  $ret $mangledName(${args.join(", ")});\n');
					default:
						// Skip non-function members.
				}
			}
		}

		buffer.add('}\n');
		File.saveContent("exported_api.h", buffer.toString());
		return fields;
	}


	static function typeToC(t:ComplexType):String {
    return switch (t) {
      // Primitive types:
      case TPath({ name: "Int" }):
        "int";
      case TPath({ name: "UInt" }):
        "unsigned int";
      case TPath({ name: "Int8" }):
        "char";
      case TPath({ name: "UInt8" }):
        "unsigned char";
      case TPath({ name: "Int16" }):
        "short";
      case TPath({ name: "UInt16" }):
        "unsigned short";
      case TPath({ name: "Int32" }):
        "int";
      case TPath({ name: "UInt32" }):
        "unsigned int";
      case TPath({ name: "Int64" }):
        "long long";
      case TPath({ name: "UInt64" }):
        "unsigned long long";
      case TPath({ name: "NativeInt" }):
        "intptr_t";
      case TPath({ name: "NativeUInt" }):
        "uintptr_t";
      case TPath({ name: "NativeFloat" }):
        "float";
      case TPath({ name: "NativeBool" }):
        "bool";
      case TPath({ name: "NativeString" }):
        "const char*";
      case TPath({ name: "NativeVoid" }):
        "void";
      case TPath({ name: "NativeDynamic" }):
        "void*";
      case TPath({ name: "Float" }):
        "float";
      case TPath({ name: "Bool" }):
        "bool";
      case TPath({ name: "String" }):
        "const char*";
      case TPath({ name: "Void" }):
        "void";
      case TPath({ name: "Dynamic" }):
        "void*";
  
      // For Array types, we can simply return void* for now.
      // A more advanced mapping might inspect the generic parameter.
      case TPath({ name: "Array" }):
        "void*";
  
      // Function types: mapping them to void* for now, as function pointers
      // require a more nuanced approach.
      case TFunction(_):
        "void*";
  
      // For abstract types and enums, you might want to do custom mappings.
      // For now, we fall back to void*.
      default:
        "void*";
    }
  }
  
}

#end // if macro