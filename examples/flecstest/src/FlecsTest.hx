import hxcore.flecs.Types.Float32;
import hxcore.flecs.Component;
import hxcore.flecs.Entity;
import hxcore.flecs.Flecs;
import hxcore.flecs.Observer;
import hxcore.flecs.System;
import hxcore.flecs.NativePtr;
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

    var position = Component.of(Position);
    var velocity = Component.of(Velocity);
    var destination = Component.of(Destination);
    var testComp = Component.of(TestComponent);

    System.addSystem("MoveSystem", [position, velocity], function(it) {
      it.each([position, velocity], function(pos:Position, vel:Velocity) {
        pos.x += vel.x * it.dt;
        pos.y += vel.y * it.dt;
        pos.z += vel.z * it.dt;
      });
    });

    Observer.addObserver([position], [Flecs.EcsOnSet], function(it) {
      Log.info('Observer: Position set');
    });

    var entity = Entity.create("Entity");
    entity.add(position);
    entity.add(velocity);
    entity.add(destination);
    entity.add(testComp);

    entity.set(velocity, {x: 1.0, y: 2.0, z: 0.0});
    entity.set(position, new Position(12.0, 34.0, 0.0));

    entity.remove(velocity);

    for (i in 0...3) {
      Flecs.progress(1.0);
        if (entity.has(velocity)) {
          var vel:Velocity = entity.get(velocity);
          Log.info('Velocity: (${vel.x}, ${vel.y})');
        }
      var pos:Position = entity.get(position);
      var tc:TestComponent = entity.get(testComp);
      Log.info('Position: (${pos.x}, ${pos.y})');
      Log.info('TestComponent: (${tc.x}, ${tc.y})');
    }

    Flecs.fini();
  }
}
