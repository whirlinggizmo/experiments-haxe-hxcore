package core.stage;

import core.scripting.ScriptHost;
import core.ui.UIOverlay;
import core.scene.IScene;
import core.actor.ActorRegistry;
import core.camera.ICamera;
import core.ecs.EntityID;
import core.ecs.SystemRegistry;
import core.logging.Log;

class Stage implements IStage {
    var rootId:EntityID; // The ID representing the root actor
     var camera:ICamera;
    var uiLayers:Array<UIOverlay>;
    var sceneStack:Array<IScene>;
    var script:ScriptHost;

    public function new() {
        rootId = ActorRegistry.createActor(); // The faithful assistant!
        camera = null;
        uiLayers = [];
        sceneStack = [];
        script = new ScriptHost();
        script.loadScript("Test", null, null);

    }

    public function dispose():Void {
        rootId = 0;
        camera = null;
        uiLayers = null;
        sceneStack = null;
    }

    public function setCamera(camera:ICamera):Void {
        this.camera = camera;
    }

    public function getCamera():ICamera {
        return camera;
    }

    /** Adds an actor to the root container */
    public function addActor(actorId:EntityID):Void {
        // Link actorId to rootId via some form of parenting (if we choose to implement hierarchy)
        Log.debug('Actor $actorId added to the stage root $rootId');
    }

    /** Removes an actor from the root container */
    public function removeActor(actorId:EntityID):Void {
        // Unlink actorId from rootId
        Log.debug('Actor $actorId removed from the stage root $rootId');
    }

    /** Updates all actors and the stage state */
    public function update(deltaTimeMS:Int):Int {
        var err = 0;
        
        SystemRegistry.update(deltaTimeMS);

        script.invoke("onUpdate", [deltaTimeMS]);
        camera?.update(deltaTimeMS); // Update camera

        return err;
    }

    /** Renders all actors and overlays */
    public function render():Void {
        //Log.debug("Rendering Stage");
        // Render logic here
    }

    /** Adds a UI overlay */
    public function showOverlay(overlay:UIOverlay):Void {
        uiLayers.push(overlay);
    }

    /** Removes a UI overlay */
    public function hideOverlay(overlay:UIOverlay):Void {
        uiLayers.remove(overlay);
    }

    /** Pushes a new scene onto the stack */
    public function pushScene(scene:IScene):Void {
        sceneStack.push(scene);
    }

    /** Pops the current scene */
    public function popScene():Void {
        sceneStack.pop();
    }

    public function init() {}
}
