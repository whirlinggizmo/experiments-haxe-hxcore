package core.logging;

import haxe.PosInfos;


class Logger {
	static var oldTrace:Dynamic;

	public static function replaceTrace() {
		Logger.oldTrace = haxe.Log.trace; // store old function
		haxe.Log.trace = Logger.log;
	}

	public static function restoreLogger() {
		haxe.Log.trace = oldTrace;
	}

	/**
		Format the output of `log.debug` before printing it.
	**/
	public static function formatOutput(v:Dynamic, infos:PosInfos):String {
		var str = Std.string(v);
		if (infos == null)
			return str;
		var pstr = infos.fileName + ":" + infos.lineNumber;
		if (infos.customParams != null)
			for (v in infos.customParams)
				str += ", " + Std.string(v);
		return pstr + ": " + str;
	}

	/**
		Outputs `v` in a platform-dependent way.

		The second parameter `infos` is injected by the compiler and contains
		information about the position where the `log()` call was made.

		This method can be rebound to a custom function:

			var oldTrace = haxe.Log.trace; // store old function
			haxe.Log.trace = function(v, ?infos) {
			  // handle log
			}
			...
			haxe.Log.trace = oldTrace;

		If it is bound to null, subsequent calls to `log()` will cause an
		exception.
	**/
	@:inline
	public static dynamic function log(v:Dynamic, ?infos:PosInfos):Void {
		var str = Logger.formatOutput(v, infos);
		#if js
		if (js.Syntax.typeof(untyped console) != "undefined" && (untyped console).log != null)
			(untyped console).log("./" + str);
		#elseif lua
		untyped __define_feature__("use._hx_print", _hx_print(str));
		#elseif sys
		Sys.println(str);
		#else
		throw new haxe.exceptions.NotImplementedException()
		#end
	}
}
