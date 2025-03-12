package core.app;


import core.stage.IStage;


typedef AppOptions = {
    @:optional var onReady:()->Void;
    @:optional var onUpdate:(deltaTimeMS:Int)->Int;
    @:optional var onDispose:()->Void;
    
    @:optional var width:Int;
    @:optional var height:Int;
    @:optional var title:String;
    @:optional var resizable:Bool;
    @:optional var element:Dynamic;
    @:optional var background:Null<Int>;
    @:optional var vsync:Bool;
    @:optional var hardware:Bool;
    @:optional var antialiasing:Int;
    @:optional var frameRate:Int;
    @:optional var allowFullscreen:Bool;
};

interface IApp {
    /** Initialize the application with the given stage */
    function init(stage:IStage, ?options:AppOptions):Void;

    /** Update the application state */
    function update(deltaTimeMS:Int):Int;

    /** Clean up and destroy the application */
    function dispose():Void;

    /** Start running the application */
    function run(stage:IStage, ?options:AppOptions):Void;   

    /** Quit the application */
    function quit():Void;

    /** Get the name of the application */
    var name :String;
}