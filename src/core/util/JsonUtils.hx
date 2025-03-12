package core.util;

class JsonUtils {
	public static function getCircularReplacer():Dynamic->String->Dynamic {
        var maxDepth = 2;
        var currentDepth = 0;

		function replacer(key:Dynamic, value:Dynamic):Dynamic {

			if (Std.isOfType(value, String) || Std.isOfType(value, Float) || Std.isOfType(value, Int) || Std.isOfType(value, Bool) || value == null) {
				return value;
			}

            if (currentDepth > maxDepth) {
                return "...";
            }

            currentDepth++;

            if (Std.isOfType(value, Array)) {
                return "[" + value.map(replacer).join(", ") + "]";
            }

            if (Reflect.hasField(value, "keys") && Reflect.hasField(value, "get")) {
                // map?
                var keys = value.keys();
                var result = [];
                for (i in 0...keys.length) {
                    result.push(keys[i] + ": " + replacer(keys[i], value.get(keys[i])));
                }
                return "{" + result.join(", ") + "}";
            }

            if (Reflect.isObject(value)) {
                var fields = Reflect.fields(value);
                return "{" + fields.map( f -> f + ": " + replacer(f, Reflect.field(value, f)) ).join(", ") + "}";
            }

            currentDepth--;

			return Reflect.isObject(value) ? "{...}" : value;
		}

		return replacer;
	}
}
