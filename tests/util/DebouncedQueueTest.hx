package tests.util;

import utest.Test;
import utest.Assert;
import hxcore.util.DebouncedQueue;

class DebouncedQueueTest extends Test {
	function testCoalescesByKey() {
		var q = new DebouncedQueue<String>(100, (s) -> s);
		q.push("a", 0);
		q.push("a", 50);
		Assert.equals(1, q.size());
		Assert.equals(0, q.flush(99).length);
		var out = q.flush(150);
		Assert.equals(1, out.length);
		Assert.equals("a", out[0]);
	}

	function testFlushAfterWindow() {
		var q = new DebouncedQueue<String>(50);
		q.push("a", 0);
		q.push("b", 10);
		Assert.equals(0, q.flush(40).length);
		var out = q.flush(70);
		Assert.equals(2, out.length);
		Assert.equals(0, q.size());
	}
}
