package hxcore.flecs;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class SystemIterMacro {
  public static macro function register():Void {
    haxe.macro.Compiler.addGlobalMetadata(
      "",
      "@:using(hxcore.flecs.SystemIterMacro)",
      true, true, false
    );
  }

  public static macro function each(itExpr:Expr, componentsExpr:Expr, callbackExpr:Expr):Expr {
    var components = switch (componentsExpr.expr) {
      case EArrayDecl(items): items;
      default:
        Context.error("it.each expects a literal component array, e.g. [position, velocity]", componentsExpr.pos);
        [];
    };

    var fn = switch (callbackExpr.expr) {
      case EFunction(_, f): f;
      default:
        Context.error("it.each expects a callback function", callbackExpr.pos);
        null;
    };
    if (fn == null) return macro {};

    if (fn.args.length != components.length) {
      Context.error('it.each callback arg count (${fn.args.length}) must match component count (${components.length})', callbackExpr.pos);
    }

    if (components.length > 3) {
      Context.error("it.each currently supports 0-3 components", componentsExpr.pos);
    }

    var rebuiltCallback:Expr = {expr: EFunction(null, fn), pos: callbackExpr.pos};

    return switch (components.length) {
      case 0:
        macro {
          var __sysIt = $e{itExpr};
          var __sysN:Int = cast __sysIt.count;
          for (__sysI in 0...__sysN) {
            ($e{rebuiltCallback})();
          }
        };
      case 1:
        macro $e{itExpr}.each1($e{components[0]}, $e{rebuiltCallback});
      case 2:
        macro $e{itExpr}.each2($e{components[0]}, $e{components[1]}, $e{rebuiltCallback});
      case 3:
        macro $e{itExpr}.each3($e{components[0]}, $e{components[1]}, $e{components[2]}, $e{rebuiltCallback});
      default:
        macro {};
    };
  }
}
