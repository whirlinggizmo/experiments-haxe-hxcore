package core.actor;

import core.scripting.ScriptHost;
import core.ecs.EntityID;

class ActorRegistry {
	static private var actors:Map<EntityID, ScriptHost> = new Map(); // Holds loaded scripts by name
 
    static public function createActor():EntityID {
        var id = EIDGenerator.nextEID();
        var script = new ScriptHost();
        actors.set(id, script);
        return id;
    }

    static public function destroyActor(id:EntityID):Void {
        var script = actors.get(id);
        actors.remove(id);
        if (script != null) {
            script.dispose();
        }
    }

    static public function addComponent(id:EntityID, componentName:String, ?componentValues:Any):Void {
         // TODO:  ECS
    }

}