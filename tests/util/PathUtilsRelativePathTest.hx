package tests.util;

import utest.Test;
import utest.Assert;
import hxcore.util.PathUtils;
import haxe.io.Path;

class PathUtilsRelativePathTest extends Test {
	function testRelativePathSafeWithRelativeBase() {
		var cwd = Sys.getCwd();
		var base = "scripts";
		var target = Path.join([cwd, "scripts", "Test.hx"]);
		var result = PathUtils.relativePathSafe(base, target);
		Assert.equals("./Test.hx", result);
	}

	function testRelativePathSafeWithAbsoluteBase() {
		var cwd = Sys.getCwd();
		var base = Path.join([cwd, "scripts"]);
		var target = Path.join([cwd, "scripts", "Test.hx"]);
		var result = PathUtils.relativePathSafe(base, target);
		Assert.equals("./Test.hx", result);
	}
}
