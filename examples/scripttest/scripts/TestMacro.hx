package scripts;

import hxcore.scripting.Script;

/**
 * Example script that demonstrates the new macro-based namespace injection.
 * This script will be automatically compiled with the "gen" namespace prefix, 
 * so it becomes "gen.scripts.Test" instead of "scripts.Test".
 * No @:build annotation needed - the global macro handles it automatically!
 */
class Test extends Script {
    
    public function new() {
        super();
        Log.info("Test script loaded with macro-injected namespace!");
    }
    
    override public function onLoad():Void {
        Log.info("Test script onLoad() called");
        Log.info("Script name: " + scriptName);
        Log.info("Script directory: " + scriptDirectory);
    }
    
    override public function onUpdate(deltaTime:Float):Void {
        // This script doesn't need to do anything in update
    }
    
    override public function onUnload():Void {
        Log.info("Test script onUnload() called");
    }
}
