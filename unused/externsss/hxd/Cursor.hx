package hxd;

@:native("hxd.Cursor") extern enum Cursor {
	Default;
	Button;
	Move;
	TextInput;
	Hide;
	Custom(custom:hxd.Cursor.CustomCursor);
	/**
		
				When this cursor is selected, call the function itself, which can handle complex logic and is responsible to call hxd.System.setCursor
			
	**/
	Callback(f:() -> Void);
}

@:allow(hxd.System) @:native("hxd.Cursor") extern class CustomCursor {
	function new(frames:Array<Dynamic>, speed:Float, offsetX:Int, offsetY:Int):Void;
	function reset():Void;
	function update(dt:Float):Int;
	function dispose():Void;
	static function getNativeCursor(name:String):hxd.Cursor;
}