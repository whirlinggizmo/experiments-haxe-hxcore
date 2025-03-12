package core.actor;

interface IActor {
    function init():Void;
    function update(deltaTimeMS:Int):Void;
    function render():Void;
    function dispose():Void;
}