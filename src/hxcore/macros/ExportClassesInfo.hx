package hxcore.macros;

// create a macro that will filter out the given classes from the export_classes.info file
// it uses regex patterns to match classes to filter out
import haxe.macro.Context;
import haxe.macro.Expr;
import hxcore.util.ExportClassesInfoFilter;

class ExportClassesInfo {
	/**
	 * Filters out script classes from export_classes.info
	 * @param inputPath Path to the original export_classes.info file
	 * @param outputPath Path to save the filtered file
	 * @param regexPatterns Array of regex patterns to match classes to filter out
	 */
	macro public static function filterToFile(exportClassesInfoPath:String, outputPath:String, regexPatterns:Array<String>):Expr {
		// read the export_classes.info file
		var content = sys.io.File.getContent(exportClassesInfoPath);
		var filtered = ExportClassesInfoFilter.filterContent(content, regexPatterns);
		sys.io.File.saveContent(outputPath, filtered);

		return macro {
			return outputPath;
		}
	}
}
