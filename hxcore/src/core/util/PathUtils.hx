package core.util;

class PathUtils {
    public static function globToRegex(pattern:String):EReg {
		// Convert glob pattern to regular expression
		var regexPattern = StringTools.replace(pattern, ".", "\\."); // Escape dots
		regexPattern = StringTools.replace(regexPattern, "*", ".*"); // Replace '*' with '.*' to match any characters
		regexPattern = StringTools.replace(regexPattern, "?", "."); // Replace '?' with '.' to match any single character
		// Log.debug('regexPattern:' + regexPattern);
		return new EReg("^" + regexPattern + "$", "");
	}
}
