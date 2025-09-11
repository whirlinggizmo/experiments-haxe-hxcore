package hxcore.macros;

// create a macro that will filter out the given classes from the export_classes.info file
// it uses regex patterns to match classes to filter out
import haxe.macro.Context;
import haxe.macro.Expr;
import StringTools;
import EReg;

class ExportClassesInfo {
	/**
	 * Filters out script classes from export_classes.info
	 * @param inputPath Path to the original export_classes.info file
	 * @param outputPath Path to save the filtered file
	 * @param regexPatterns Array of regex patterns to match classes to filter out
	 */
	macro public static function filterToFile(exportClassesInfoPath:String, outputPath:String, regexPatterns:Array<String>):Expr {
		// read the export_classes.info file, line at a time.
		var lines = sys.io.File.getContent(exportClassesInfoPath).split("\n");

		// filter out the given classes, using regex patterns
		var filteredLines = [];
		for (line in lines) {
			var shouldKeep = true;

			// Skip empty lines
			if (StringTools.trim(line) == "") {
				filteredLines.push(line);
				continue;
			}

			// Check if line matches any exclusion pattern using regex
			for (pattern in regexPatterns) {
				var regex = new EReg(pattern, "");
				if (regex.match(line)) {
					shouldKeep = false;
					break;
				}
			}

			// Keep the line if it doesn't match any pattern
			if (shouldKeep) {
				filteredLines.push(line);
			}
		}

		// save the filtered export_classes.info file
		sys.io.File.saveContent(outputPath, filteredLines.join("\n"));

		return macro {
			return outputPath;
		}
	}
}