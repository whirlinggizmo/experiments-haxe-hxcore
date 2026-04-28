package tests.scripting;

import utest.Assert;
import utest.Test;
import hxcore.scripting.ScriptPathResolver;

class ScriptPathResolverTest extends Test {
	function testCompiledScriptPathUsesPackageStructure() {
		Assert.equals("gen/scripts/Test.cppia", ScriptPathResolver.compiledScriptPath("gen", "scripts.Test"));
	}

	function testCompiledScriptRelativePathUsesPackageStructure() {
		Assert.equals("scripts/Test.js", ScriptPathResolver.compiledScriptRelativePath("scripts.Test", "js"));
	}

	function testGeneratedClassNamePrefixesNamespace() {
		Assert.equals("gen.scripts.Test", ScriptPathResolver.generatedClassName("scripts.Test", "gen"));
		Assert.equals("scripts.Test", ScriptPathResolver.generatedClassName("scripts.Test", ""));
	}

	function testRelativeSourcePathWithinRoot() {
		Assert.equals("./Test.hx", ScriptPathResolver.relativeSourcePathWithinRoot("scripts", "scripts.Test"));
		Assert.equals("./nested/Test.hx", ScriptPathResolver.relativeSourcePathWithinRoot("scripts", "scripts.nested.Test"));
		Assert.equals(null, ScriptPathResolver.relativeSourcePathWithinRoot("scripts", "mods.Test"));
	}
}
