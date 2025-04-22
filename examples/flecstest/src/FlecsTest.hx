import hxcore.flecs.Flecs;
import cpp.UInt32;
import hxcore.logging.Log;


class FlecsTest {
    public static function main() {
        Flecs.init();
        Log.info('Flecs version: ${Flecs.version()}');

        // Get the component ID for "Position" from the C API
        final PositionId:Int = Flecs.getComponentId("Position");
        final VelocityId:Int = Flecs.getComponentId("Velocity");
        final DestinationId:Int = Flecs.getComponentId("Destination");

        Flecs.registerObserver([PositionId, VelocityId, DestinationId], [Flecs.EcsOnSet], (entityId:UInt32, componentId:UInt32, eventId:UInt32, component:Dynamic) -> {
            if (componentId == PositionId) {
                // convert componentPtr to Vector2
                //var vecPtr:cpp.RawPointer<Vector2> = cast componentPtr;
                //var vec:Vector2 = vecPtr[0];
                //trace('Position: (${vec.x}, ${vec.y})');
            }
        });


        // Register the system for entities with Position
       //Flecs.registerSystem("TestSystem", testSystemCallback, [positionComponentId, velocityComponentId]);

        // Create an entity with Position
        var entityId:UInt32 = Flecs.createEntity("Entity");
        Flecs.addComponent(entityId, PositionId);
        Flecs.addComponent(entityId, VelocityId);

        //Flecs.setComponentData(entityId, positionComponentId, &{x: 0.0, y: 0.0});
        //Flecs.setComponentData(entityId, velocityComponentId, &{x: 1.0, y: 1.0});
        
        //Flecs.setVelocity(entityId, 1.0, 1.0);
        //Flecs.setPosition(entityId, 0.0, 0.0);
        var pos:Position = {x: 0.0, y: 0.0};
        var vel:Velocity = {x: 1.0, y: 1.0};
        Flecs.setComponentData(entityId, PositionId, pos);
        Flecs.setComponentData(entityId, VelocityId, vel);

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

        //Flecs.setPosition(entityId, components[0].x + components[1].x, components[0].y + components[1].y);
    }
}