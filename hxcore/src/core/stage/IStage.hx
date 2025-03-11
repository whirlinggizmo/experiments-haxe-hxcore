package core.stage;

import core.camera.ICamera;
import core.ecs.EntityID;

interface IStage {
    /** Initialize the stage, setting up core state. */
    function init():Void;

    /** Update the stage (e.g., actor logic). */
    function update(deltaTimeMS:Int):Int;

    /** Render the stage to the screen. */
    function render():Void;

    /** Dispose of the stage. */
    function dispose():Void;
    
    /** Add an actor to the stage. */
    function addActor(actorId:EntityID):Void;

    /** Remove an actor from the stage. */
    function removeActor(actorId:EntityID):Void;

    /** Access the camera (if any). */
    function getCamera():ICamera;

    /** Set the camera. */
    function setCamera(camera:ICamera):Void;

}
