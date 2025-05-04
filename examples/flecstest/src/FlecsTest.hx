import hxcore.flecs.Flecs;
import cpp.UInt64;
import cpp.UInt32;
import cpp.Float32;
import hxcore.logging.Log;
import sys.thread.Thread;

/**
 * A test component with two float fields.
 */
@:structInit
class TestComponent {
    public var x:Float32;
    public var y:Float32;
}

/**
 * A test class that demonstrates how to use Flecs in Haxe.
 */
class FlecsTest {
    /**
     * A system callback that updates entities with the TestComponent.
     */
    public static function testSystemCallback(entities:Array<UInt64>, components:cpp.Pointer<cpp.RawPointer<cpp.Void>>, entityCount:UInt32, delta_time:Float32):Void {
        for (i in 0...entities.length) {
            var entity:UInt64 = entities[i];
           // var componentsPtr:cpp.RawPointer<cpp.Void> = components[i];
           // var component:TestComponent = cast(componentsPtr[0], TestComponent);
           // component.x += delta_time;
           // component.y += delta_time;
        }
    }
    
    /**
     * The main entry point of the application.
     */
    public static function main() {
        Flecs.init();
        Log.info('Flecs version: ${Flecs.version()}');

        // Get the component ID for "Position" from the C API
        final PositionId:Int = Flecs.getComponentId("Position");
        final VelocityId:Int = Flecs.getComponentId("Velocity");
        final DestinationId:Int = Flecs.getComponentId("Destination");

        // create a test component
        var tcSize = cpp.Native.sizeof(TestComponent);
        trace('TestComponent size: $tcSize, Expected: 8');

        var posSize = cpp.Native.sizeof(Position);
        trace('Position size: $posSize, Expected: 8');

        var velSize = cpp.Native.sizeof(Velocity);
        trace('Velocity size: $velSize, Expected: 8');

        var destSize = cpp.Native.sizeof(Destination);
        trace('Destination size: $destSize, Expected: 12');

        final TestComponentId:Int = Flecs.createComponent("TestComponent", tcSize);
        trace('TestComponentId: $TestComponentId');

       /*
        Flecs.registerObserver([PositionId, VelocityId, DestinationId], [Flecs.EcsOnSet], (entityId:UInt32, componentId:UInt32, eventId:UInt32, component:Dynamic) -> {
            if (componentId == PositionId) {
                // convert componentPtr to Vector2
                //var vecPtr:cpp.RawPointer<Vector2> = cast componentPtr;
                //var vec:Vector2 = vecPtr[0];
                //trace('Position: (${vec.x}, ${vec.y})');
            }
        });
*/

        // Register the system for entities with our test component
       //Flecs.registerSystem("TestSystem", [TestComponentId], testSystemCallback);

        // Create an entity with Position, Velocity, and our test component
        var entityId:UInt32 = Flecs.createEntity("Entity");
        Flecs.addComponent(entityId, PositionId);
        Flecs.addComponent(entityId, VelocityId);
        //Flecs.addComponent(entityId, TestComponentId);

        var pos:Position = {x: 0.0, y: 0.0};
        var vel:Velocity = {x: 1.0, y: 1.0};
        var tc:TestComponent = {x: 0.0, y: 0.0};
        Flecs.setComponent(entityId, PositionId, pos);
        Flecs.setComponent(entityId, VelocityId, vel);
        //Flecs.setComponent(entityId, TestComponentId, addressof(tc));

        // Run the Flecs loop
        
        // loop for 1000 times, simulating 60 FPS
        for (i in 0...10) {
            Flecs.progress(0); // Simulate 60 FPS
            var posPtr:cpp.Pointer<Position> = Flecs.getComponentPtr(entityId, PositionId);
            var velPtr:cpp.Pointer<Velocity> = Flecs.getComponentPtr(entityId, VelocityId);
            //var tcPtr:cpp.Pointer<TestComponent> = Flecs.getComponentPtr(entityId, TestComponentId);

            // Explicit null checks
            if (posPtr != null) {
                trace('Position: (${posPtr.ref.x}, ${posPtr.ref.y})');
            } else {
                trace('Position pointer is null');
            }
            if (velPtr != null) {
                trace('Velocity: (${velPtr.ref.x}, ${velPtr.ref.y})');
            } else {
                trace('Velocity pointer is null');
            }
            /*
            if (tcPtr != null) {
                trace('TestComponent: (${tcPtr.ref.x}, ${tcPtr.ref.y})');
            } else {
                trace('TestComponent pointer is null');
            }
            */            
            //posPtr.ref.x += 1; // Keep modifications commented out for now
            //posPtr.ref.y += 1;
            
            //sys.thread.Thread.sleep(0.016); // approx 60 FPS - Commented out for faster test run
        }

        Flecs.fini();
    }

}