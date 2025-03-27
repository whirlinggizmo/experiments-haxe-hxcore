package hxcore.ecs;

class EntityManager {
    static var entities:Map<EntityID, Entity> = new Map();

    static public function createEntity(?eid:EntityID):Entity {
        var entity = new Entity(eid);
        entities.set(entity.eid, entity);
        return entity;
    }

    static public function getEntity(eid:EntityID):Entity {
        return entities.get(eid);
    }

    static public function destroyEntity(eid:EntityID):Void {
        var entity = entities.get(eid);
        if (entity != null) {
            entity.dispose();
            entities.remove(eid);
        }
    }

    static public function clear():Void {
        for (entity in entities) {
            entity.dispose();
        }
        entities.clear();
    }
    
    //  update
    static public function update(deltaTimeMS:Float):Bool {
        for (entity in entities) {
            entity.update(deltaTimeMS);
        }
        return false;
    }

        //  fixed update
        static public function fixedUpdate(frameDurationMS:Float):Bool {
            for (entity in entities) {
                entity.fixedUpdate(frameDurationMS);
            }
            return false;
        }




}