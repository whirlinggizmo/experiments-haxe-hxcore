import haxe.macro.Context;
import haxe.macro.Expr;

class MyMacro {
	public static function build():Array<Field> {
		// get existing fields from the context from where build() is called
		var fields = Context.getBuildFields();
		trace(fields);

		// append a field
		fields.push({
			name: "STATIC_VAR",
			access: [Access.APublic, Access.AStatic, Access.AInline],
			kind: FieldType.FVar(macro :Float, macro $v{1.5}),
			pos: Context.currentPos(),
		});

		return fields;
	}
}
