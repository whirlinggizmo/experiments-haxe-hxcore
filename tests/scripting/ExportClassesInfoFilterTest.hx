package tests.scripting;

import utest.Test;
import utest.Assert;
import hxcore.util.ExportClassesInfoFilter;

class ExportClassesInfoFilterTest extends Test {
	function testFiltersMatchingLines() {
		var content = [
			"class scripts.Test",
			"class hxcore.scripting.Script",
			"file scripts/Test.hx",
			""
		].join("\n");

		var result = ExportClassesInfoFilter.filterContent(content, [
			"^class scripts\\..*$"
		]);
		var lines = result.split("\n");

		Assert.isFalse(lines.contains("class scripts.Test"));
		Assert.isTrue(lines.contains("class hxcore.scripting.Script"));
		Assert.isTrue(lines.contains("file scripts/Test.hx"));
	}

	function testCanExcludeBaseScriptFromExportList() {
		var content = [
			"class hxcore.scripting.Script",
			"class scripts.Test"
		].join("\n");

		var result = ExportClassesInfoFilter.filterContent(content, [
			"^class hxcore\\.scripting\\.Script$"
		]);
		var lines = result.split("\n");

		Assert.isFalse(lines.contains("class hxcore.scripting.Script"));
		Assert.isTrue(lines.contains("class scripts.Test"));
	}

	function testKeepsEmptyLines() {
		var content = "class a\n\nclass b\n";
		var result = ExportClassesInfoFilter.filterContent(content, ["^class a$"]);
		var emptyCount = 0;
		for (line in result.split("\n")) {
			if (line == "") emptyCount++;
		}
		Assert.isTrue(emptyCount >= 1);
	}
}
