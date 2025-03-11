package core.ecs;

class ECSComponent {
}

class ECSComponentRegistry {
    static var components = new Map<String, ECSComponent>();

    static public function registerComponent(name:String, component:ECSComponent):Void {
        components.set(name, component);
    }

    static public function unregisterComponent(name:String):Void {
        components.remove(name);
    }
}