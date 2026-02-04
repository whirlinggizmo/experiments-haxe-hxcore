package hxcore.scripting;

enum OverrideMode {
	ExternalFirst;
	InternalOnly;
	ExternalOnly;
}

enum ScriptSource {
	External;
	Internal;
	None;
}

class ScriptResolution {
	public static function chooseSource(hasExternal:Bool, hasInternal:Bool, mode:OverrideMode):ScriptSource {
		switch (mode) {
			case ExternalFirst:
				if (hasExternal) return External;
				if (hasInternal) return Internal;
				return None;
			case InternalOnly:
				return hasInternal ? Internal : None;
			case ExternalOnly:
				return hasExternal ? External : None;
		}
	}

	public static function chooseSourceWithExternalEnabled(hasExternal:Bool, hasInternal:Bool, externalEnabled:Bool, mode:OverrideMode):ScriptSource {
		if (!externalEnabled) {
			return chooseSource(false, hasInternal, mode == OverrideMode.ExternalOnly ? OverrideMode.ExternalOnly : OverrideMode.InternalOnly);
		}
		return chooseSource(hasExternal, hasInternal, mode);
	}
}
