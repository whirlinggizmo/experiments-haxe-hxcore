package core.actor;

import core.ecs.EntityID;

var actorProxies:Map<EntityID, ActorProxy> = new Map();

class ActorProxy {
    public var id:EntityID;
  
    public function new(id:EntityID) {
        this.id = id;   
    }

    public function get(id:EntityID):ActorProxy {
        var actorProxy = actorProxies.get(id); 
        if (actorProxy != null) {
            return actorProxy;
        }
        actorProxy = new ActorProxy(id);
        actorProxies.set(id, actorProxy);
        return actorProxy;
    }
}