package core.logging;

#if js
import js.Syntax;
#end


 enum abstract LogLevel(Int) from Int to Int {
	var Debug = 10;
	var Info = 20;
	var Warning = 30;
	var Error = 40;
	var Fatal = 50;

	static var longest:Int = 20;

	public inline function toString():String {
		return switch (this) {
			default: "DEBUG";
			case Info: "INFO";
			case Warning: "WARN";
			case Error: "ERROR";
			case Fatal: "FATAL";
		}
	}

	public function format(s:String, color:Bool = true, ?pos:haxe.PosInfos, ?tag:String):String {

		if (Log.writeRawOutput) return '$s'; // no brackets/info/line, etd

		var d = Date.now().toString();
		// rjk removed date, it was getting in the way
		d = '';

		var p = StringTools.lpad(pos.fileName, " ", longest) + ":" + StringTools.lpad(Std.string(pos.lineNumber), " ", 4) + ":";

		// rjk changed the position layout so vscode will see it as a link
		p = pos.fileName + ":" + pos.lineNumber;

		// level from the enum
		var l = toString();

		// previous format
		// fmt = '$d $p  $l: $s';

		#if js
		var fmt = '[' + (tag != null ? tag : '$l') + ']: $s';
		#else
		var fmt = '[' + (tag != null ? tag : '$l') + '] [./$p]: $s';

		var colorize = color && Sys.systemName() != "Windows";
		if (pos.fileName.length > longest)
			longest = pos.fileName.length;

		if (color) {
			return switch (this) {
				default: '\033[38;5;6m' + fmt + '\033[m';
				case Info: '\033[38;5;12m' + fmt + '\033[m';
				case Warning: '\033[38;5;3m' + fmt + '\033[m';
				case Error: '\033[38;5;1m' + fmt + '\033[m';
				case Fatal: '\033[38;5;5m' + fmt + '\033[m';
			}
		} else {
			return fmt;
		}
		#end


		return fmt;
	}
}


class Log {
	private static var isInitialized:Bool = false;
	private static var minLevel:LogLevel = LogLevel.Debug;

	@:allow(core.logging.Log)
	private static var writeRawOutput:Bool = false;

	public static var rawOutput(get, set):Bool;
	public static function get_rawOutput():Bool {
		return writeRawOutput;
	}
	public static function set_rawOutput(value:Bool):Bool {
		writeRawOutput = value;
		return writeRawOutput;
	}
		
	private static function initialize():Void {
		if (!isInitialized) {
			isInitialized = true;
			// do some fixup on javascript console so we can get the actual line number
			#if js
			Syntax.code("
                if (console?.log) console.log = Function.prototype.bind.call(console.log, console);
            ");
			#end
		}
	}

	public static inline function write(s:Dynamic, level:LogLevel = LogLevel.Info, ?pos:haxe.PosInfos, ?tag:String):Void {
		if (!isInitialized) {
			initialize();
		}

		// #if (hxp_debug && !(hxp_no_log))
		//var minLevel = #if (hxp_loglevel == 'info') Info #elseif (hxp_loglevel == 'warning') Warning #elseif (hxp_loglevel == 'error') Error #elseif (hxp_loglevel == 'critical') Critical #else Debug #end;
		if (Std.int(level) >= Std.int(minLevel)) {
			#if neko
			var p:haxe.PosInfos = {
				fileName: "",
				lineNumber: 0,
				customParams: null,
				methodName: "",
				className: ""
			};
			#else
			var p:haxe.PosInfos = null;
			#end
			#if js
			var msg = level.format(Std.string(s), false, pos, tag);
			switch (level) {
				case Debug:
					Syntax.code("console.log('%c' + {0}, 'color: #4DD0E1; font-weight: bold')", [msg]);
				case Info:
					Syntax.code("console.log('%c' + {0}, 'color: #2196F3; font-weight: bold')", [msg]);
				case Warning:
					Syntax.code("console.warn('%c' + {0}, 'color: #FFA726; font-weight: bold')", [msg]);
				case Error:
					Syntax.code("console.error('%c' + {0}, 'color: #EF5350; font-weight: bold')", [msg]);
				case Fatal:
					Syntax.code("console.error('%c' + {0}, 'color: #E91E63; font-weight: bold; font-size: 1.1em')", [msg]);
			}
			#else
			//haxe.Log.trace(level.format(Std.string(s), true, pos, tag), p);
			Sys.println(level.format(Std.string(s), true, pos, tag));
			#end
			#if !macro
			// if (haxepunk.debug.Console.enabled) {
			//	HXP.engine.console.log(level.format(Std.string(s), false, pos));
			// }
			#end
		}
		// #end
	}
		

	public static inline function debug(s:Dynamic, ?pos:haxe.PosInfos, ?tag:String)
		write(s, LogLevel.Debug, pos, tag);

	public static inline function info(s:Dynamic, ?pos:haxe.PosInfos, ?tag:String)
		write(s, LogLevel.Info, pos, tag);

	public static inline function warn(s:Dynamic, ?pos:haxe.PosInfos, ?tag:String)
		write(s, LogLevel.Warning, pos, tag);

	public static inline function error(s:Dynamic, ?pos:haxe.PosInfos,	?tag:String)
		write(s, LogLevel.Error, pos, tag);

	public static inline function fatal(s:Dynamic, ?pos:haxe.PosInfos, ?tag:String)
		write(s, LogLevel.Fatal, pos, tag);

	public static inline function log(s:Dynamic, ?pos:haxe.PosInfos, ?tag:String) 
		write(s, LogLevel.Info, pos, (tag == null ? "LOG" : tag));

	public static function setLevel(level:LogLevel):Void {
		minLevel = level;
	}

	
	public static function getLevel():LogLevel {
		return minLevel;
	}

	public static inline function isMinimalOutput():Bool 
		return writeRawOutput;

}
