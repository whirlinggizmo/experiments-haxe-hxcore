package hxcore.camera;


interface ICamera {
    function update(delta:Float):Void;
    function render():Void;
}