package tests.scripting;

import utest.Test;
import utest.Assert;
import hxcore.scripting.ScriptResolution;
import hxcore.scripting.ScriptResolution.OverrideMode;
import hxcore.scripting.ScriptResolution.ScriptSource;

class ScriptResolutionTest extends Test {
	function testExternalFirst() {
		Assert.equals(ScriptSource.External, ScriptResolution.chooseSource(true, true, OverrideMode.ExternalFirst));
		Assert.equals(ScriptSource.Internal, ScriptResolution.chooseSource(false, true, OverrideMode.ExternalFirst));
		Assert.equals(ScriptSource.External, ScriptResolution.chooseSource(true, false, OverrideMode.ExternalFirst));
		Assert.equals(ScriptSource.None, ScriptResolution.chooseSource(false, false, OverrideMode.ExternalFirst));
	}

	function testInternalOnly() {
		Assert.equals(ScriptSource.Internal, ScriptResolution.chooseSource(true, true, OverrideMode.InternalOnly));
		Assert.equals(ScriptSource.Internal, ScriptResolution.chooseSource(false, true, OverrideMode.InternalOnly));
		Assert.equals(ScriptSource.None, ScriptResolution.chooseSource(true, false, OverrideMode.InternalOnly));
		Assert.equals(ScriptSource.None, ScriptResolution.chooseSource(false, false, OverrideMode.InternalOnly));
	}

	function testExternalOnly() {
		Assert.equals(ScriptSource.External, ScriptResolution.chooseSource(true, true, OverrideMode.ExternalOnly));
		Assert.equals(ScriptSource.None, ScriptResolution.chooseSource(false, true, OverrideMode.ExternalOnly));
		Assert.equals(ScriptSource.External, ScriptResolution.chooseSource(true, false, OverrideMode.ExternalOnly));
		Assert.equals(ScriptSource.None, ScriptResolution.chooseSource(false, false, OverrideMode.ExternalOnly));
	}

	function testExternalDisabledForcesInternalOnly() {
		Assert.equals(ScriptSource.Internal, ScriptResolution.chooseSourceWithExternalEnabled(true, true, false, OverrideMode.ExternalFirst));
		Assert.equals(ScriptSource.Internal, ScriptResolution.chooseSourceWithExternalEnabled(true, true, false, OverrideMode.InternalOnly));
		Assert.equals(ScriptSource.None, ScriptResolution.chooseSourceWithExternalEnabled(true, false, false, OverrideMode.ExternalOnly));
	}
}
