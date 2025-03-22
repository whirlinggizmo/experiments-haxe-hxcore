package hxcore.scene;

interface IScene {
    function update(deltaTimeMS:Float):Void;
    function render():Void;
}