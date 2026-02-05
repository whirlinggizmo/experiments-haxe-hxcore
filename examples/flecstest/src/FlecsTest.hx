import cpp.Float32;
import cpp.Native;
import cpp.Pointer;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Component;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Entity;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Flecs;
import hxcore.flecs.flecs_wrapper.bindings.haxe.FlecsWrapper.Position;
import hxcore.flecs.flecs_wrapper.bindings.haxe.FlecsWrapper.Velocity;
import hxcore.flecs.flecs_wrapper.bindings.haxe.FlecsWrapper.Destination;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Observer;
import hxcore.logging.Log;

@:structAccess
@:structInit
@:nativeGen
@:native("TestComponent")
class TestComponent {
  public var x:Float32;
  public var y:Float32;

  public function new() {}
}

class FlecsTest {
  public static function main() {
    Flecs.init();
    Log.info('Flecs version: ${Flecs.version()}');

    var posSize = Native.sizeof(Position);
    var velSize = Native.sizeof(Velocity);
    var destSize = Native.sizeof(Destination);
    var tcSize = Native.sizeof(TestComponent);

    Log.info('Position size: ${posSize}');
    Log.info('Velocity size: ${velSize}');
    Log.info('Destination size: ${destSize}');
    Log.info('TestComponent size: ${tcSize}');

    var position = Component.require("Position");
    var velocity = Component.require("Velocity");
    var destination = Component.require("Destination");
    var testComp = Component.create("TestComponent", tcSize);

    Observer.addObserver([position], [Flecs.EcsOnSet], function(it) {
      if (it.componentId != position.id) {
        return;
      }
      var ptr:cpp.Pointer<Position> = it.colPtrByComponentTyped(position);
      if (ptr == null) {
        return;
      }
      var first = ptr.ref;
      Log.info('Observer: Position set -> (${first.x}, ${first.y})');
    });

    var entity = Entity.create("Entity");
    entity.add(position);
    entity.add(velocity);
    entity.add(destination);
    entity.add(testComp);

    var pos = new Position(12.0, 34.0);
    var posPtr = Pointer.addressOf(pos);
    entity.setPtr(position, posPtr);
    if (pos.x == -9999) {
      trace(pos);
    }

    for (i in 0...2) {
      Flecs.progress(0);
      var posPtr:cpp.Pointer<Position> = entity.getPtr(position);
      var velPtr:cpp.Pointer<Velocity> = entity.getPtr(velocity);
      var tcPtr:cpp.Pointer<TestComponent> = entity.getPtr(testComp);

      if (posPtr != null) {
        Log.info('Position: (${posPtr.ref.x}, ${posPtr.ref.y})');
      }
      if (velPtr != null) {
        Log.info('Velocity: (${velPtr.ref.x}, ${velPtr.ref.y})');
      }
      if (tcPtr != null) {
        Log.info('TestComponent: (${tcPtr.ref.x}, ${tcPtr.ref.y})');
      }
    }

    Flecs.fini();
  }
}
