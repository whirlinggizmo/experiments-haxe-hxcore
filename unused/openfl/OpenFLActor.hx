package;

import core.actor.IActor;
import openfl.display.Sprite;

/**
 * Experimental implementation of IActor using OpenFL.
 */
class OpenFLActor implements IActor {
    public var sprite:Sprite;
    public var x:Float;
    public var y:Float;
    public var rotation:Float;
    public var speed:Float;

    public function new() {
        this.x = 0;
        this.y = 0;
        this.rotation = 0;
        this.speed = 50;
        sprite = new Sprite();
    }

    public function init():Void {
        sprite.graphics.beginFill(0xFF0000); // Red square
        sprite.graphics.drawRect(-25, -25, 50, 50);
        sprite.graphics.endFill();
        sprite.x = this.x;
        sprite.y = this.y;
    }

    public function update(deltaTimeMS:Float):Void {
        var deltaTimeSec = deltaTimeMS / 1000;
        x += speed * deltaTimeSec;
        rotation += 30 * deltaTimeSec;

        sprite.x = x;
        sprite.rotation = rotation;
    }

    public function render():Void {
        // OpenFL handles rendering automatically
    }

    public function dispose():Void {
        sprite.graphics.clear();
        sprite.parent?.removeChild(sprite);
        sprite = null;
    }
}
