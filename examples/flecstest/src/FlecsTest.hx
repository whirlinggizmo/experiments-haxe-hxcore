import hxcore.flecs.Types.Float32;
import hxcore.flecs.Types.Ref;
import hxcore.flecs.Component;
import hxcore.flecs.ComponentMacro;
import hxcore.flecs.Entity;
import hxcore.flecs.Flecs;
import hxcore.flecs.Observer;
import hxcore.flecs.System;

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

    var position = ComponentMacro.ofType(Position);
    var velocity = ComponentMacro.ofType(Velocity);
    var destination = ComponentMacro.ofType(Destination);
    var testComp = ComponentMacro.ofType(TestComponent);

    System.addSystem("MoveSystem", [position, velocity], function(it) {
      it.each2(position, velocity, function(pos:Ref<Position>, vel:Ref<Velocity>) {
        pos.ref.x += vel.ref.x * it.dt;
        pos.ref.y += vel.ref.y * it.dt;
        pos.ref.z += vel.ref.z * it.dt;
      });
    });

    Observer.addObserver([position], [Flecs.EcsOnSet], function(it) {
      var ptr:Ref<Position> = it.colPtrByComponentTyped(position);
      if (ptr == null) return;
      Log.info('Observer: Position set -> (${ptr.ref.x}, ${ptr.ref.y})');
    });

    var entity = Entity.create("Entity");
    entity.add(position);
    entity.add(velocity);
    entity.add(destination);
    entity.add(testComp);

    entity.set(velocity, new Velocity(1.0, 2.0, 0.0));
    entity.set(position, new Position(12.0, 34.0, 0.0));

    for (i in 0...3) {
      Flecs.progress(1.0);
      var pos:Ref<Position> = entity.tryGet(position);
      var vel:Ref<Velocity> = entity.tryGet(velocity);
      var tc:Ref<TestComponent> = entity.tryGet(testComp);
      if (pos != null) Log.info('Position: (${pos.ref.x}, ${pos.ref.y})');
      if (vel != null) Log.info('Velocity: (${vel.ref.x}, ${vel.ref.y})');
      if (tc != null) Log.info('TestComponent: (${tc.ref.x}, ${tc.ref.y})');
    }

    Flecs.fini();
  }
}
