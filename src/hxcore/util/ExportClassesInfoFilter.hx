package hxcore.util;

import StringTools;
import EReg;

class ExportClassesInfoFilter {
	public static function filterContent(content:String, excludePatterns:Array<String>):String {
		var lines = content.split("\n");
		var filtered = filterLines(lines, excludePatterns);
		return filtered.join("\n");
	}

	public static function filterLines(lines:Array<String>, excludePatterns:Array<String>):Array<String> {
		var filteredLines:Array<String> = [];
		for (line in lines) {
			var trimmed = StringTools.trim(line);
			if (trimmed == "") {
				filteredLines.push(line);
				continue;
			}

			var shouldKeep = true;
			for (pattern in excludePatterns) {
				var regex = new EReg(pattern, "");
				if (regex.match(line)) {
					shouldKeep = false;
					break;
				}
			}

			if (shouldKeep) {
				filteredLines.push(line);
			}
		}

		return filteredLines;
	}
}
