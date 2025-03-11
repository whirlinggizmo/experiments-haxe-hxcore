package core.camera;


interface ICamera {
    function update(delta:Float):Void;
    function render():Void;
}