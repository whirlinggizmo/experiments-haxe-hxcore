import hxcore.flecs.NativePtr;
import hxcore.flecs.Component;
import hxcore.flecs.Entity;
import hxcore.flecs.Flecs;
import hxcore.flecs.System;
import hxcore.flecs.Types.Float32;

@:component("MyComponent")
class MyComponent {
  public var x:Float32;
  public var y:Float32;

  public function new(x:Float32 = 0.0, y:Float32 = 0.0) {
    this.x = x;
    this.y = y;
  }
}

@:component("SysPos")
class SysPos {
  public var x:Float32;
  public var y:Float32;

  public function new(x:Float32 = 0.0, y:Float32 = 0.0) {
    this.x = x;
    this.y = y;
  }
}

@:component("SysVel")
class SysVel {
  public var x:Float32;
  public var y:Float32;

  public function new(x:Float32 = 0.0, y:Float32 = 0.0) {
    this.x = x;
    this.y = y;
  }
}

class SystemTest {
  public static function main() {
    Flecs.init();

    var position = Component.of(SysPos);
    var velocity = Component.of(SysVel);
    var myComponent = Component.of(MyComponent);

    var entity = Entity.create("Entity");
    entity.set(position, new SysPos(0.0, 0.0));
    entity.set(velocity, new SysVel(1.0, 1.5));
    entity.add(myComponent);

    var sysId = System.addSystem("TestSystem", [position, velocity], function(it) {
      it.each([position, velocity], function(pos:SysPos, vel:SysVel) {
        pos.x += vel.x * it.dt;
        pos.y += vel.y * it.dt;
      });
    });

    if (sysId == 0) {
      throw "Failed to register system";
    }

    for (i in 0...10) {
      Flecs.progress(0.1);
    }

    var posPtr:NativePtr<SysPos> = entity.tryGet(position);
    if (posPtr != null) {
      var pos = posPtr.ref;
      trace('Position: (${pos.x}, ${pos.y})');
    }

    Flecs.fini();
  }
}
