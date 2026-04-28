package tests;

import utest.Runner;
import utest.ui.Report;
import tests.scripting.DummyTest;
import tests.scripting.ExportClassesInfoFilterTest;
import tests.scripting.ScriptResolutionTest;
import tests.scripting.ScriptPathResolverTest;
import tests.scripting.RuntimeIntegrationTest;
import tests.scripting.RuntimeConfigIntegrationTest;
import tests.scripting.CppiaOverrideIntegrationTest;
import tests.scripting.CppiaHcrIntegrationTest;
import tests.scripting.JsLoaderIntegrationTest;
#if sys
import tests.util.PathUtilsRelativePathTest;
#end
import tests.util.DebouncedQueueTest;

class RunTests {
	static function main() {
		var runner = new Runner();
		runner.addCase(new DummyTest());
		runner.addCase(new ExportClassesInfoFilterTest());
		runner.addCase(new ScriptResolutionTest());
		runner.addCase(new ScriptPathResolverTest());
		runner.addCase(new RuntimeIntegrationTest());
		runner.addCase(new RuntimeConfigIntegrationTest());
#if cpp
		runner.addCase(new CppiaOverrideIntegrationTest());
		runner.addCase(new CppiaHcrIntegrationTest());
#end
#if js
		runner.addCase(new JsLoaderIntegrationTest());
#end
#if sys
		runner.addCase(new PathUtilsRelativePathTest());
#end
		runner.addCase(new DebouncedQueueTest());
		Report.create(runner);
		runner.run();
	}
}
