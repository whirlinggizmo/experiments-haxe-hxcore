package;

import haxe.Timer;
import core.stage.IStage;
import core.app.IApp;

import OpenFLApp as App; // prototype openfl app implementation, replace with your own
import OpenFLStage as Stage; // prototype openfl stage implementation, replace with your own
//import core.app.App as App;
//import core.stage.Stage as Stage;

import core.logging.Log;

class Main {
	public static function main():Void {

		function ready():Void {
			Log.debug('Ready!');
			var stage:IStage = new Stage();
			var app:IApp = new App();
			app.run(stage);
		}

		// Note:
		// In debug builds, we add a small delay before starting the app.
		// This gives IDEs and debuggers time to attach their breakpoints
		// and source maps. Without this delay, we have to refresh
		// the page after launching to hit breakpoints.
		//#if debug
		//Timer.delay(ready, 0);
		//#else
		ready();
		//#end
	}
}
