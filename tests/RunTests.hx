package tests;

import utest.Runner;
import utest.ui.Report;
import tests.scripting.DummyTest;
import tests.scripting.ExportClassesInfoFilterTest;
import tests.scripting.ScriptResolutionTest;
import tests.scripting.ScriptChangeCoalescerTest;
import tests.scripting.RuntimeIntegrationTest;
import tests.scripting.RuntimeConfigIntegrationTest;
import tests.scripting.CppiaOverrideIntegrationTest;
import tests.scripting.CppiaHcrIntegrationTest;
import tests.util.PathUtilsRelativePathTest;
import tests.util.DebouncedQueueTest;

class RunTests {
	static function main() {
		var runner = new Runner();
		runner.addCase(new DummyTest());
		runner.addCase(new ExportClassesInfoFilterTest());
		runner.addCase(new ScriptResolutionTest());
		runner.addCase(new ScriptChangeCoalescerTest());
		runner.addCase(new RuntimeIntegrationTest());
		runner.addCase(new RuntimeConfigIntegrationTest());
#if cpp
		runner.addCase(new CppiaOverrideIntegrationTest());
		runner.addCase(new CppiaHcrIntegrationTest());
#end
		runner.addCase(new PathUtilsRelativePathTest());
		runner.addCase(new DebouncedQueueTest());
		Report.create(runner);
		runner.run();
	}
}
