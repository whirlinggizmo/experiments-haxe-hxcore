import cpp.Float32;
import cpp.Native;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Component;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Entity;
import hxcore.flecs.flecs_wrapper.bindings.haxe.Flecs;
import hxcore.flecs.flecs_wrapper.bindings.haxe.System;

@:structAccess
@:structInit
@:nativeGen
@:native("MyComponent")
class MyComponent {
  public var x:Float32;
  public var y:Float32;

  public function new() {}
}

@:structAccess
@:structInit
@:nativeGen
@:native("SysPos")
class SysPos {
  public var x:Float32;
  public var y:Float32;

  public function new() {}
}

@:structAccess
@:structInit
@:nativeGen
@:native("SysVel")
class SysVel {
  public var x:Float32;
  public var y:Float32;

  public function new() {}
}

class SystemTest {
  public static function main() {
    Flecs.init();

    var position = Component.create("SysPos", Native.sizeof(SysPos));
    var velocity = Component.create("SysVel", Native.sizeof(SysVel));
    var myComponent = Component.create("MyComponent", Native.sizeof(MyComponent));

    var entity = Entity.create("Entity");
    var posVal = new SysPos();
    posVal.x = 0.0;
    posVal.y = 0.0;
    entity.set(position, posVal);

    var velVal = new SysVel();
    velVal.x = 1.0;
    velVal.y = 1.5;
    entity.set(velocity, velVal);
    entity.add(myComponent);

    var sysId = System.addSystemIds("TestSystem", [position.id, velocity.id], function(it) {
      var count:Int = cast it.count;
      for (i in 0...count) {
        var p:cpp.Pointer<SysPos> = it.colTyped(position.id, i);
        var v:cpp.Pointer<SysVel> = it.colTyped(velocity.id, i);
        if (p != null && v != null) {
          p.ref.x += v.ref.x * it.dt;
          p.ref.y += v.ref.y * it.dt;
        }
      }
    });

    if (sysId == 0) {
      throw "Failed to register system";
    }

    for (i in 0...10) {
      Flecs.progress(0.1);
    }

    var p2Ptr:cpp.Pointer<SysPos> = entity.getPtr(position);
    if (p2Ptr != null) {
      var p2 = p2Ptr.ref;
      trace('Position: (${p2.x}, ${p2.y})');
    }

    Flecs.fini();
  }
}
