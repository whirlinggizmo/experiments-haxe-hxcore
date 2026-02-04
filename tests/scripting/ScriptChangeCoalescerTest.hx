package tests.scripting;

import utest.Test;
import utest.Assert;
import hxcore.scripting.ScriptChangeCoalescer;

class ScriptChangeCoalescerTest extends Test {
	function testCoalescesByTimeWindow() {
		var c = new ScriptChangeCoalescer(100);
		c.push("a", 0);
		c.push("b", 20);
		Assert.equals(0, c.flush(50).length);
		var out = c.flush(120);
		Assert.equals(2, out.length);
	}

	function testCoalescesDuplicatePaths() {
		var c = new ScriptChangeCoalescer(50);
		c.push("scripts/Test.hx", 0);
		c.push("scripts/Test.hx", 10);
		var out = c.flush(80);
		Assert.equals(1, out.length);
	}

	function testWindowExtendsOnNewChange() {
		var c = new ScriptChangeCoalescer(100);
		c.push("scripts/Test.hx", 0);
		Assert.equals(0, c.flush(90).length);
		c.push("scripts/Test.hx", 95);
		Assert.equals(0, c.flush(180).length);
		var out = c.flush(210);
		Assert.equals(1, out.length);
	}
}
