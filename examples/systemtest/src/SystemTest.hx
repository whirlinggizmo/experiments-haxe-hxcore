import hxcore.flecs.Flecs;
import cpp.UInt32;



class SystemTest {
    public static function main() {
        Flecs.init();

        // Get the component ID for "Position" from the C API
        var positionComponentId:Int = Flecs.getComponentId("Position");
        var velocityComponentId:Int = Flecs.getComponentId("Velocity");
        var myComponentId:Int = Flecs.createComponent("MyComponent", sizeof(MyComponent));


        // Register the system for entities with Position
       Flecs.registerSystem("TestSystem", testSystemCallback, [positionComponentId, velocityComponentId]);

        // Create an entity with Position
        var entityId:UInt32 = Flecs.createEntity("Entity");
        Flecs.addComponent(entityId, positionComponentId);
        Flecs.addComponent(entityId, velocityComponentId);
        Flecs.setVelocity(entityId, 1.0, 1.0);
        Flecs.setPosition(entityId, 0.0, 0.0);

        // Run the Flecs loop
        
        // loop for 1000 times, simulating 60 FPS
        for (i in 0...1000) {
            Flecs.progress(0); // Simulate 60 FPS
        }

        Flecs.fini();
    }

    // System callback: receives entityId, pointer array, and count
    static function testSystemCallback(
        entityId:UInt32,
        components:Array<Dynamic>,
        numComponents:UInt32
    ):Void {
        //trace('testSystemCallback called for entity $entityId with $numComponents components');
        trace('Position: (${components[0].x}, ${components[0].y})');

        Flecs.setPosition(entityId, components[0].x + components[1].x, components[0].y + components[1].y);
    }
}