import hxcore.flecs.Flecs;
import cpp.UInt64;
import cpp.UInt32;
import cpp.Float32;
import hxcore.logging.Log;
import sys.thread.Thread;

/**
 * A test component with two float fields.
 */
 @:structAccess
 @:structInit
 @:nativeGen
 @:native("TestComponent")
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
            trace('Entity: $entity');
            trace('Delta time: $delta_time');
            //var componentsPtr:cpp.RawPointer<cpp.Void> = components[i];
            //var component:TestComponent = cast(componentsPtr[0], TestComponent);
            //trace('TestComponent: (${component.x}, ${component.y})');
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

        var tcSize = cpp.Native.sizeof(TestComponent);
        trace('TestComponent size: $tcSize, Expected: 8');

        var posSize = cpp.Native.sizeof(Position);
        trace('Position size: $posSize, Expected: 8');

        var velSize = cpp.Native.sizeof(Velocity);
        trace('Velocity size: $velSize, Expected: 8');

        var destSize = cpp.Native.sizeof(Destination);
        trace('Destination size: $destSize, Expected: 12');

        // create a test component
        final TestComponentId:Int = Flecs.createComponent("TestComponent", 8);
        trace('TestComponentId: $TestComponentId');

       
        Flecs.registerObserver([PositionId], [Flecs.EcsOnSet], (entityId:UInt32, componentId:UInt32, eventId:UInt32, componentPtrInt:UIntPtr) -> {
            Log.debug('Observer called for entity $entityId, component $componentId, event $eventId');
            if (componentId == PositionId) {
                Log.debug('Observer: Handling Position component');
                Log.debug('Observer: Received componentPtrInt: $componentPtrInt');

                // 1. Cast UIntPtr back to cpp.RawPointer<cpp.Void>, ensuring intermediate cast to uintptr_t
                Log.debug('Observer: Attempting cast UIntPtr -> void*');
                var voidPtr:cpp.RawPointer<cpp.Void> = untyped __cpp__('(void*)(uintptr_t){0}', componentPtrInt);
                Log.debug('Observer: voidPtr after cast: $voidPtr');

                if (voidPtr == null) {
                    Log.warn('Observer: componentPtrInt resulted in null voidPtr');
                    return;
                }

                // Read floats directly from raw pointer offsets, bypassing .ref
                Log.debug('Observer: Attempting untyped __cpp__ float reads at offsets 0 and 4');
                try {
                    // Cast void* to float* and dereference for x (offset 0)
                    var tempX:Float = untyped __cpp__('*((float*){0})', voidPtr);
                    // Cast void* to float*, add 1 (pointer arithmetic for offset 4), and dereference for y
                    var tempY:Float = untyped __cpp__('*((float*){0} + 1)', voidPtr);
                    Log.debug('Observer: Successfully read floats via untyped __cpp__');
                    trace('Observer: Position (from readFloat): (${tempX}, ${tempY})');
                } catch (e:Any) {
                     Log.error('Observer: Error using untyped __cpp__ for float reads: $e');
                }

            } else {
                 Log.debug('Observer: Ignoring component $componentId');
            }
        });


        // Register the system for entities with our test component
       //Flecs.registerSystem("TestSystem", [TestComponentId], testSystemCallback);

        // Create an entity with Position, Velocity, and our test component
        var entityId:UInt32 = Flecs.createEntity("Entity");
        // add the position component.  This should trigger the observer callback since it does a set 
        Flecs.addComponent(entityId, PositionId);

        //Flecs.addComponent(entityId, VelocityId);
        //Flecs.addComponent(entityId, TestComponentId);

        var pos:Position = {x: 12.0, y: 34.0};
        //var vel:Velocity = {x: 1.0, y: 1.0};
        //var tc:TestComponent = {x: 123.0, y: 456.0};
        
        // set the position component.  This should trigger the observer callback again
        Flecs.setComponent(entityId, PositionId, pos);

        //Flecs.setComponent(entityId, VelocityId, vel);
        //Flecs.setComponent(entityId, TestComponentId, tc);

        // Run the Flecs loop
        
        // loop for 1000 times, simulating 60 FPS
        for (i in 0...2) {
            Flecs.progress(0); // Simulate 60 FPS
            var posPtr:cpp.Pointer<Position> = Flecs.getComponentPtr(entityId, PositionId);
            var velPtr:cpp.Pointer<Velocity> = Flecs.getComponentPtr(entityId, VelocityId);
            var tcPtr:cpp.Pointer<TestComponent> = Flecs.getComponentPtr(entityId, TestComponentId);

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
            if (tcPtr != null) {
                trace('TestComponent: (${tcPtr.ref.x}, ${tcPtr.ref.y})');
            } else {
                trace('TestComponent pointer is null');
            }            
            //posPtr.ref.x += 1; // Keep modifications commented out for now
            //posPtr.ref.y += 1;
            
            //sys.thread.Thread.sleep(0.016); // approx 60 FPS - Commented out for faster test run
        }

        Flecs.fini();
    }

}