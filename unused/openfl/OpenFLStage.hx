package;

import openfl.display.Sprite;
import core.stage.IStage;
import core.camera.ICamera;
import core.actor.IActor;
import core.ecs.EntityID;
import haxe.ds.IntMap;
import core.logging.Log;

/**
 * OpenFL implementation of IStage.
 */
class OpenFLStage implements IStage {
    public var root:Sprite;
    var actors:IntMap<IActor>;
    var actorCount:Int;
    var camera:ICamera;

    public function new() {
        actors = new IntMap<IActor>();
        actorCount = 0;
        camera = null;
    }

    /**
     * Initialize the stage with default settings.
     */
    public function init():Void {
        root = new Sprite();
        
        Log.debug("OpenFL Stage initialized!");
    }

    /**
     * Update all actors on the stage.
     * @param deltaTimeMS Time elapsed since the last update (in milliseconds).
     * @return 0 if successful, non-zero error code otherwise.
     */
    public function update(deltaTimeMS:Int):Int {
        try {
            //Log.debug('Stage Update Start. DeltaTimeMS: $deltaTimeMS');

            for (actorId in actors.keys()) {
                var actor = actors.get(actorId);
                if (actor == null) {
                    Log.warn('Actor with EntityID $actorId is null.');
                    continue;
                }

                actor.update(deltaTimeMS);
            }

            //Log.debug('Stage Update Complete. Actor Count: $actorCount');
            return 0; // Success
        } catch (e:Dynamic) {
            Log.error('Error during Stage.update: $e');
            return 1; // Generic error code
        }
    }

    /**
     * Render all actors (handled automatically by OpenFL).
     */
    public function render():Void {
        // OpenFL handles rendering implicitly
    }

    /**
     * Add an actor to the stage.
     * @param actorId Unique identifier for the actor.
     */
    public function addActor(actorId:EntityID):Void {
        if (!actors.exists(actorId)) {
            Log.debug('Adding actor with EntityID: $actorId');
            var actor:IActor = new OpenFLActor(); // Experimental Actor
            actor.init();
            actors.set(actorId, actor);
            actorCount++;

            if (Std.isOfType(actor, OpenFLActor)) {
                var openFLActor:OpenFLActor = cast actor;
                root.addChild(openFLActor.sprite);
            }
        }
    }

    /**
     * Remove an actor from the stage.
     * @param actorId Unique identifier for the actor.
     */
    public function removeActor(actorId:EntityID):Void {
        if (actors.exists(actorId)) {
            Log.debug('Removing actor with EntityID: $actorId');
            var actor = actors.get(actorId);
            actor.dispose();
            actors.remove(actorId);
            actorCount--;

            if (Std.isOfType(actor, OpenFLActor)) {
                var openFLActor:OpenFLActor = cast actor;
                root.removeChild(openFLActor.sprite);
            }
        }
    }

    /**
     * Dispose of the stage and all actors.
     */
    public function dispose():Void {
        Log.debug("Disposing OpenFL Stage...");
        for (actorId in actors.keys()) {
            removeActor(actorId);
        }
        actors = null;
        root = null;
        camera = null;
        actorCount = 0;
    }

    /**
     * Get the currently active camera.
     * @return The active ICamera instance.
     */
    public function getCamera():ICamera {
        return camera;
    }

    /**
     * Set a camera for the stage.
     * @param camera The ICamera instance to use.
     */
    public function setCamera(camera:ICamera):Void {
        this.camera = camera;
    }
}
