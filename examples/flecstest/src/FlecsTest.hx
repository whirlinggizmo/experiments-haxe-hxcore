import cpp.Float32;
import cpp.Native;
import cpp.Pointer;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Component;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Entity;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Flecs;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Observer;
import hxcore.flecs.flecs_wrapper.bindings.haxe.System;
import hxcore.logging.Log;

@:component("Position")
class Position {
  public var x:Float32;
  public var y:Float32;
  public var z:Float32;
  public function new(x:Float32 = 0.0, y:Float32 = 0.0, z:Float32 = 0.0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
}

@:component("Velocity")
class Velocity {
  public var x:Float32;
  public var y:Float32;
  public var z:Float32;
  public function new(x:Float32 = 0.0, y:Float32 = 0.0, z:Float32 = 0.0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
}

@:component("Destination")
class Destination {
  public var x:Float32;
  public var y:Float32;
  public var z:Float32;
  public var speed:Float32;
  public function new(x:Float32 = 0.0, y:Float32 = 0.0, z:Float32 = 0.0, speed:Float32 = 0.0) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.speed = speed;
  }
}

@:component("TestComponent")
class TestComponent {
  public var x:Float32;
  public var y:Float32;
  public var idx:Int;
  public function new(x:Float32 = 0.0, y:Float32 = 0.0, idx:Int = 0) {
    this.x = x;
    this.y = y;
    this.idx = idx;
  }
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

    var position = Component.create("Position", posSize);
    var velocity = Component.create("Velocity", velSize);
    var destination = Component.create("Destination", destSize);
    var testComp = Component.create("TestComponent", tcSize);

    System.addSystem("MoveSystem", [position, velocity], function(it) {
      for (i in 0...cast it.count) {
        var pos:Pointer<Position> = it.colByComponentTyped(position, i);
        var vel:Pointer<Velocity> = it.colByComponentTyped(velocity, i);
        pos.ref.x += vel.ref.x * it.dt;
        pos.ref.y += vel.ref.y * it.dt;
        pos.ref.z += vel.ref.z * it.dt;
      }
    });

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

    var vel:Velocity = new Velocity(1.0, 2.0, 0.0);
    var velPtr:Pointer<Velocity> = untyped __cpp__("::cpp::Pointer<Velocity>(&{0})", vel);
    entity.setPtr(velocity, velPtr);

    var pos = new Position(12.0, 34.0, 0.0);
    var posPtr:Pointer<Position> = untyped __cpp__("::cpp::Pointer<Position>(&{0})", pos);
    entity.setPtr(position, posPtr);
    if (pos.x == -9999) {
      trace(pos);
    }

    for (i in 0...3) {
      Flecs.progress(1.0);
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
