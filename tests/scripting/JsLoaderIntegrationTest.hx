package tests.scripting;

#if js
import utest.Test;
import utest.Assert;
import hxcore.scripting.ScriptConfig;
import hxcore.scripting.ScriptRuntime;
import hxcore.scripting.ScriptHost;
import hxcore.scripting.ScriptResolution.OverrideMode;

class JsLoaderIntegrationTest extends Test {
	function setup() {
		FakeScript.loadCount = 0;
		FakeScript.updateCount = 0;
	}

	function testJsLoaderLoadsInternalScript() {
		var cfg = new ScriptConfig();
		cfg.externalEnabled = false;
		cfg.overrideMode = OverrideMode.ExternalFirst;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);
		var loaded = false;

		host.loadScript("tests.scripting.FakeScript", _ -> {}, (h) -> {
			loaded = h != null;
		});

		Assert.isTrue(loaded);
		Assert.equals(1, FakeScript.loadCount);

		host.update(16.0);
		Assert.equals(1, FakeScript.updateCount);

		host.dispose();
		runtime.dispose();
	}

	function testJsLoaderRespectsExternalOnlyWhenExternalDisabled() {
		var cfg = new ScriptConfig();
		cfg.externalEnabled = false;
		cfg.overrideMode = OverrideMode.ExternalOnly;

		var runtime = new ScriptRuntime(cfg);
		var host = new ScriptHost(runtime);
		var createdWasNull = false;

		host.loadScript("tests.scripting.FakeScript", (created) -> {
			createdWasNull = created == null;
		}, _ -> {});

		Assert.isTrue(createdWasNull);
		Assert.equals(0, FakeScript.loadCount);

		host.dispose();
		runtime.dispose();
	}
}
#end
