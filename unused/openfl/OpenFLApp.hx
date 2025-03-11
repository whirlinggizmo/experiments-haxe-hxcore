package;

import haxe.Exception;
import haxe.Timer;
import core.stage.IStage;
import core.app.IApp;
import core.logging.Log;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import core.scripting.ScriptInstance;
#if js
import js.Syntax;
#end

// We subclass the Application class and override the createWindow and update methods
// Alternatively, we could have subscribed to the Application.onWindowCreate and Application.onUpdate events
// and handled them in our App.
// In theory, this is faster since it doesn't have to go through the event system?
class InternalApp extends openfl.display.Application {
	private var sprite:Sprite;
	private var onReadyEvent:() -> Void;
	private var onUpdateEvent:(deltaTime:Int) -> Void;
	private var onDisposeEvent:() -> Void;
	private var _appWindow:lime.ui.Window;

	/*
    public var stage(default, null):openfl.display.Stage;
	public function get_stage():openfl.display.Stage {
		return _appWindow?.stage;
	}
    */

    public function getStage():openfl.display.Stage {
        return _appWindow?.stage;
    }

	public function new() {
		super();
	}

	public function init(?options:AppOptions) {
		try {
			options ??= {};

			this.onReadyEvent = options.onReady;
			this.onUpdateEvent = options.onUpdate;
			this.onDisposeEvent = options.onDispose;

			// let the user specify the render element as a id name ('myRenderCanvas') or a DOM element
			#if (js && html5)
			if (Std.is(options.element, String)) {
				options.element = js.Syntax.code("document.getElementById(`${options.element}`)");
			}
            if (options.element == null) {
				throw new Exception("No render element/canvas provided, required for HTML5");
			}
			#end

			_appWindow = this.createWindow({
				width: options.width ?? 800,
				height: options.height ?? 600,
				title: options.title ?? "OpenFL Application",
				resizable: options.resizable ?? true,
				// html requires a render element, either a canvas or a parent div
				element: options.element ?? null,
				frameRate: options.frameRate ?? 60,
				parameters: {
					allowFullscreen: options.allowFullscreen ?? false
				},
				context: {
					background: options.background ?? 0x172B80,
					antialiasing: options.antialiasing ?? 0,
					hardware: options.hardware ?? true,
					vsync: options.vsync ?? true
				}
			});

			if (onReadyEvent != null) {
				onReadyEvent();
			}
		} catch (e) {
			Log.error('Error initializing OpenFLApp: $e');
		}
	}

	override public function onWindowClose():Void {
		if (onDisposeEvent != null) {
			onDisposeEvent();
		}
	}

	override public function update(deltaTimeMS:Int):Void {
		if (onUpdateEvent != null) {
			onUpdateEvent(deltaTimeMS);
		}
	}

	public function exit():Void {
		if (_appWindow != null) {
			_appWindow.close();
			_appWindow = null;
			// this should generate a onWindowClose event if it's the last window?
			// will we ever have more than one window?
		}
	}
}

class OpenFLApp implements IApp {
	var stage:IStage;
	var frameRate:Int;
	var quitFlag:Bool = false;
	var lastFrameTimeSec:Float = 0.0;
    var currentTimeSec:Float = 0.0;
	var deltaTimeMS:Int = 0;
	var isInitialized:Bool = false;
	var userOnReady:() -> Void;
	var userOnUpdate:(deltaTimeMS:Int) -> Int;
	var userOnDispose:() -> Void;
	var _app:InternalApp;

	// fun!
	var testSprite:Sprite;
    var testScript:ScriptInstance;

	public function new() {}

	public function init(stage:IStage, ?options:AppOptions):Void {
		if (isInitialized) {
			return;
		}

		Log.debug("Initializing OpenFLApp...");

		this.stage = stage;
		quitFlag = false;
		lastFrameTimeSec = Timer.stamp();

		// Create our wrapped openfl/lime app. 
		_app = new InternalApp();

        // it needs a window, so let's adjust the incoming options
		options ??= {};

        // if the user wants to know about ready/update, we'll pass it along
		userOnReady = options.onReady;
		userOnUpdate = options.onUpdate;
		userOnDispose = options.onDispose;

		// map the callbacks to our functions
		options.onReady = onReady;
		options.onUpdate = onUpdate;
		options.onDispose = onDispose;

		// apply some defaults
		options.element = options.element ?? "renderCanvas";
		options.frameRate = options.frameRate ?? 60;

		// init it.  The onReady callback will be called when the window is created
		_app.init(options);
	}

	// callback from the internal openfl app
	function onReady():Void {
		Log.debug("OpenFL Application Ready!");

		this.stage.init();
		lastFrameTimeSec = Timer.stamp();

		isInitialized = true;

		// if the user wants to know about ready/update, we'll pass it along
		if (userOnReady != null) {
			userOnReady();
		}

		// for fun!
		testSprite = new Sprite();
        _app.getStage().addChild(testSprite);
        testSprite.x = _app.getStage().stageWidth / 2;
        testSprite.y = _app.getStage().stageHeight / 2;
		
		var img = BitmapData.loadFromFile("https://localhost:4444/img/favicon.png");
		img.onComplete((i) -> {
			Log.debug("Image loaded");
			var bitmap = new Bitmap(i);
			testSprite.addChild(bitmap);
            bitmap.x = -bitmap.width / 2;
            bitmap.y = -bitmap.height / 2;
		});
		img.onError((error) -> {
			Log.debug('Image load error: $error');
		});

        testScript = new ScriptInstance();
        testScript.loadScript("Test");


		// no more fun.
	}

	/////////////////////////////////////
	// callback from the internal openfl app
	function onUpdate(deltaTimeMS:Int):Int {
		if (!isInitialized) {
			return 0;
		}

		// yes, I know the application provides a delta time, but I like my own :)
		currentTimeSec = Timer.stamp();
		this.deltaTimeMS = Std.int((currentTimeSec - lastFrameTimeSec) * 1000.0);
		lastFrameTimeSec = currentTimeSec;

		var err = update(deltaTimeMS);
		if (quitFlag || (err != 0)) {
			dispose();
		}

		return err;
	}

	// the typical update loop
	public function update(deltaTimeMS:Int):Int {
		var err = 0;

        final wrappedSprite = {
            x: testSprite.x,
            y: testSprite.y,
            scaleX: testSprite.scaleX,
            scaleY: testSprite.scaleY,
            rotation: testSprite.rotation,
            move: (x:Float, y:Float) -> {
                testSprite.x += x;
                testSprite.y += y;
            },
            rotate: (angle:Float) -> {
                testSprite.rotation += angle;
            },
            scale: (x:Float, y:Float) -> {
                testSprite.scaleX += x;
                testSprite.scaleY += y;
            },
            setPosition: (x:Float, y:Float) -> {
                testSprite.x = x;
                testSprite.y = y;
            },
            setRotation: (angle:Float) -> {
                testSprite.rotation = angle;
            },
            setScale: (x:Float, y:Float) -> {
                testSprite.scaleX = x;
                testSprite.scaleY = y;
            }
        }

		// fun!
		if (testSprite != null) {
			/*
            testSprite.rotation += (360/2000) * deltaTimeMS; // rotate 360 degrees over 2 seconds
           // uniformly scale the sprite with sin over time
            testSprite.scaleX = Math.sin(currentTimeSec) * ((5 - 1) / 2) + ((5 + 1) / 2);
            testSprite.scaleY = testSprite.scaleX;

            Log.debug("Rotation: " + testSprite.rotation);
            Log.debug("Scale: " + testSprite.scaleX);
*/
            if (testScript != null) {
                testScript.callFunction("updateSprite", wrappedSprite, currentTimeSec, deltaTimeMS);
            }
  
		}
		// no more fun.

		try {
			err = stage.update(deltaTimeMS);
			if (err != 0) {
				return err;
			}

			// if the user wants to know about ready/update, we'll pass it along
			if (userOnUpdate != null) {
				err = userOnUpdate(deltaTimeMS);
				if (err != 0) {
					return err;
				}
			}
			stage.render();
		} catch (e) {
			Log.debug('Update Error: $e');
			return 1; // Return error code
		}
		return 0; // Success
	}

	/////////////////////////////////////
	// callback from the internal openfl app
	function onDispose():Void {
		if (!isInitialized) {
			return;
		}
		dispose();
	}

	// We are going away, let's clean up
	public function dispose():Void {
		Log.debug("Disposing OpenFLApp...");
		if (!isInitialized) {
			return;
		}
		isInitialized = false;

		stage.dispose();

		if (userOnDispose != null) {
			userOnDispose();
		}

		if (_app != null) {
			_app = null; // Clean up the Lime app reference
			openfl.system.System.exit(0);
		}
	}

	/**
	 * Helper function to init and run the app.  Fairly empty because we are using the openfl/lime app to handle the loop
	 */
	public function run(stage:IStage, ?options:AppOptions):Void {
		Log.debug("Running OpenFLApp...");
		init(stage, options);
		_app.exec(); // Start the Lime application event loop, instead of us pumping update
	}

	/**
	 * Quit the application gracefully.
	 */
	public function quit():Void {
		Log.debug("Quitting OpenFLApp...");
		quitFlag = true;
	}
}
