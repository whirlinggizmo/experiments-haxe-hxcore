package core.ecs;

class ECSSystem {
    public var name:String;
    public var enabled:Bool;
    public var update:Float->Int;
}


class SystemRegistry {
    static var ecsSystems = [];

    static public function registerSystem(system:ECSSystem):Void {
        // check to make sure system isn't already registered
        if (ecsSystems.contains(system)) {
            return;
        }

        ecsSystems.push(system);
    }

    static public function unregisterSystem(system:ECSSystem):Void {
        ecsSystems.remove(system);
    }

    static public function update(deltaTime:Float):Int {
        for (system in ecsSystems) {
            var err = system.update(deltaTime);
            if (err != 0) {
                return err; 
            }
        }
        return 0;
    }
}