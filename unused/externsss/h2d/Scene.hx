package h2d;

/**
 Viewport alignment when scaling mode supports it. See `ScaleMode`.
 */
/**
	
		Viewport alignment when scaling mode supports it. See `ScaleMode`.
	
**/
@:native("h2d.Scene") extern enum ScaleModeAlign {
	/**
		 Anchor Scene viewport horizontally to the left side of the window. When passed to `verticalAlign` it will be treated as Center. 
	**/
	Left;
	/**
		 Anchor Scene viewport horizontally to the right side of the window. When passed to `verticalAlign` it will be treated as Center. 
	**/
	Right;
	/**
		 Anchor to the center of the window. 
	**/
	Center;
	/**
		 Anchor Scene viewport vertically to the top of the window. When passed to `horizontalAlign` it will be treated as Center. 
	**/
	Top;
	/**
		 Anchor Scene viewport vertically to the bottom of the window. When passed to `horizontalAlign` it will be treated as Center. 
	**/
	Bottom;
}

/**
 Scaling mode of the 2D Scene.
 
 Set via `Scene.scaleMode`.
 
 See ScaleMode2D sample for usage showcase.
 */
/**
	
		Scaling mode of the 2D Scene.
	
		Set via `Scene.scaleMode`.
	
		See ScaleMode2D sample for usage showcase.
	
**/
@:native("h2d.Scene") extern enum ScaleMode {
	/**
		
				Matches scene size to window size. `width` and `height` of Scene will match window size. Default scaling mode.
			
	**/
	Resize;
	/**
		
				Sets constant Scene size and stretches it to cover entire window. This behavior is same as old `setFixedSize` method.
		
				@param width The width of the internal Scene viewport.
				@param height The height of the internal Scene viewport.
			
	**/
	Stretch(width:Int, height:Int);
	/**
		
				Sets constant Scene size and upscales it with preserving the aspect-ratio to fit the window.
		
				With `800x600` window, `LetterBox(320, 260)` will result in center-aligned Scene of size `320x260` upscaled to fit into the window.
				With same window but setting of `LetterBox(320, 260, true, Left, Top)` would result in the same Scene internal size,
				upscaled to `640x480` resolution and anchored to the top-left corner of the window.
		
				Note that while it's called LetterBox, there is no viewport rendering clipping apart from the out-of-bounds culling in `RenderContext.drawTile` / `Object.emitTile`.
		
				@param width The width of the internal Scene viewport.
				@param height The height of the internal Scene viewport.
				@param integerScale When enabled, upscaling is performed only with integer increments (1x, 2x, 3x, etc) and can be used to achieve pixel-perfect scaling.
				While enabled, the Scene won't be downscaled when internal viewport is larger than the window size and will remain at 1x zoom. Default: `false`.
				@param horizontalAlign The horizontal viewport anchoring rule. Accepted values are `Left`, `Center` and `Right`. Default: `Center`.
				@param verticalAlign The vertical viewport anchoring rule. Accepted values are `Top`, `Center` and `Bottom`. Default: `Center`.
		
			
	**/
	LetterBox(width:Int, height:Int, ?integerScale:Bool, ?horizontalAlign:h2d.Scene.ScaleModeAlign, ?verticalAlign:h2d.Scene.ScaleModeAlign);
	/**
		
				Sets constant Scene size, scale and alignment. Does not perform any adaptation to the window size apart from alignment.
		
				With `800x600` window, `Fixed(200, 150, 2, Left, Center)` will result in the Scene size of `200x150`, and visually upscaled to `400x300`, and aligned to a middle-left of the window.
		
				@param width The width of the internal Scene viewport.
				@param height The height of the internal Scene viewport.
				@param zoom The scaling multiplier of internal viewport when rendering onto the screen.
				@param horizontalAlign The horizontal viewport anchoring rule. Accepted values are `Left`, `Center` and `Right`. Default: `Center`.
				@param verticalAlign The vertical viewport anchoring rule. Accepted values are `Top`, `Center` and `Bottom`. Default: `Center`.
		
			
	**/
	Fixed(width:Int, height:Int, zoom:Float, ?horizontalAlign:h2d.Scene.ScaleModeAlign, ?verticalAlign:h2d.Scene.ScaleModeAlign);
	/**
		
				Upscales/downscales the Scene internal viewport according to `level` and matches Scene size to `ceil(window size / level)`.
		
				With `800x600` window, `Zoom(2)` will result in the `400x300` Scene size upscaled to fill the entire window.
			
	**/
	Zoom(level:Float);
	/**
		
				Ensures that the Scene size will be of the minimum specified size.
		
				Automatically calculates zoom level based on provided size according to `min(window width / min width, window height / min height)`, then applies same scaling as `Zoom(level)`.
				The behavior is similar to `LetterBox`, however instead of constant internal viewport size, Scene size will change to cover the entire window.
		
				`minWidth` or `minHeight` can be set to `0` in order to force scaling adjustment account only for either horizontal of vertical window size.
				If both are `0`, results are undefined.
		
				With `800x600` window, `AutoZoom(320, 260, false)` will result in the Scene size of `347x260`. `AutoZoom(320, 260, true)` will result in the size of `400x300`.
		
				@param minWidth The minimum width of the internal Scene viewport.
				@param minHeight The minimum height of the internal Scene viewport.
				@param integerScale When enabled, upscaling is performed only with integer increments (1x, 2x, 3x, etc) and can be used to achieve pixel-perfect scaling.
				While enabled, the Scene won't be downscaled when internal viewport is larger than the window size and will remain at 1x zoom. Default: `false`.
		
			
	**/
	AutoZoom(minWidth:Int, minHeight:Int, ?integerScaling:Bool);
}

/**
 The root class for a 2D scene. All root objects are added to it before being drawn on screen.
 */
/**
	
		The root class for a 2D scene. All root objects are added to it before being drawn on screen.
	
**/
@:native("h2d.Scene") extern class Scene extends h2d.Layers implements hxd.SceneEvents.InteractiveScene implements h3d.IDrawable {
	/**
		
				Create a new 2D scene. A default 2D scene is already available in `hxd.App.s2d`.
			
	**/
	function new():Void;
	/**
		
				The current width (in pixels) of the scene. Can change if the screen gets resized or `scaleMode` changes.
			
	**/
	var width(default, null) : Int;
	/**
		
				The current height (in pixels) of the scene. Can change if the screen gets resized or `scaleMode` changes.
			
	**/
	var height(default, null) : Int;
	/**
		
				Horizontal scale of a scene when rendering to the screen.
		
				Can change if the screen gets resized or `scaleMode` changes.
			
	**/
	var viewportScaleX(default, null) : Float;
	/**
		
				Vertical scale of a scene when rendering to the screen.
		
				Can change if the screen gets resized or `scaleMode` changes.
			
	**/
	var viewportScaleY(default, null) : Float;
	/**
		
				The current mouse X coordinates (in pixels) relative to the current `Scene.interactiveCamera`.
			
	**/
	var mouseX(get, null) : Float;
	/**
		
				The current mouse Y coordinates (in pixels) relative to the current `Scene.interactiveCamera`.
			
	**/
	var mouseY(get, null) : Float;
	/**
		
				The zoom factor of the scene, allows to set a fixed x2, x4 etc. zoom for pixel art
				When setting a zoom > 0, the scene resize will be automatically managed.
			
	**/
	@:deprecated("zoom is deprecated, use scaleMode = Zoom(v) instead")
	@:dox(hide)
	var zoom(get, set) : Int;
	/**
		
				Scene scaling mode.
		
				Important thing to keep in mind - Scene does not clip rendering to it's scaled size and
				graphics can render outside of it. However `RenderContext.drawTile` (and consecutively `Object.emitTile`) does check for those bounds and
				will clip out tiles that are outside of the scene bounds.
			
	**/
	var scaleMode(default, set) : h2d.Scene.ScaleMode;
	/**
		
				List of all cameras attached to the Scene. Should contain at least one camera to render (created by default).
		
				Override `h2d.Camera.layerVisible` method to filter out specific layers from camera rendering.
		
				To add or remove cameras use `Scene.addCamera` and `Scene.removeCamera` methods.
			
	**/
	var cameras(get, never) : haxe.ds.ReadOnlyArray<h2d.Camera>;
	/**
		
				Alias to the first camera in the camera list: `cameras[0]`
			
	**/
	var camera(get, never) : h2d.Camera;
	/**
		
				Camera instance that handles the scene events.
		
				Due to Heaps structure, only one Camera can work with the Interactives.
				Contrary to rendering, event handling does not check if layer is visible for the camera or not.
		
				Should never be null. When set, if Camera does not belong to the Scene, it will be added with `Scene.addCamera`.
				Would cause an exception when trying to remove current interactive camera from the list.
			
	**/
	var interactiveCamera(default, set) : h2d.Camera;
	/**
		
				Controls the default value for `h2d.Drawable.smooth`. Default: `false`
			
	**/
	var defaultSmooth(get, set) : Bool;
	/**
		
				The current Scene renderer. Can be customized.
			
	**/
	var renderer(get, set) : h2d.RenderContext;
	@:dox(hide)
	@:noCompletion
	function setEvents(events:hxd.SceneEvents):Void;
	@:deprecated("zoom is deprecated, use scaleMode = Zoom(v) instead")
	private function get_zoom():Int;
	@:deprecated("zoom is deprecated, use scaleMode = Zoom(v) instead")
	private function set_zoom(v:Int):Int;
	private function set_scaleMode(v:h2d.Scene.ScaleMode):h2d.Scene.ScaleMode;
	private function get_renderer():h2d.RenderContext;
	private function set_renderer(v:h2d.RenderContext):h2d.RenderContext;
	private function set_interactiveCamera(cam:h2d.Camera):h2d.Camera;
	/**
		
				Adds a Camera to the Scene camera list with optional index at which it is added.
				@param cam The Camera instance to add.
				@param pos Optional index at which the camera will be inserted.
			
	**/
	function addCamera(cam:h2d.Camera, ?pos:Int):Void;
	/**
		
				Removes the Camera from the Scene camera list.
				Attempting to remove current `Scene.interactiveCamera` would cause an exception.
			
	**/
	function removeCamera(cam:h2d.Camera):Void;
	/**
		
				Set the fixed size for the scene, will prevent automatic scene resizing when screen size changes.
			
	**/
	@:deprecated("setFixedSize is deprecated, use scaleMode = Stretch(w, h) instead")
	@:dox(hide)
	@:noCompletion
	function setFixedSize(w:Int, h:Int):Void;
	/**
		
				Recalculates the scene viewport parameters based on `scaleMode`.
			
	**/
	@:dox(hide)
	@:noCompletion
	function checkResize():Void;
	private function get_mouseX():Float;
	private function get_mouseY():Float;
	@:dox(hide)
	@:noCompletion
	function dispatchListeners(event:hxd.Event):Void;
	@:dox(hide)
	@:noCompletion
	function isInteractiveVisible(i:hxd.SceneEvents.Interactive):Bool;
	/**
		
				Returns the topmost visible Interactive at the specified coordinates.
			
	**/
	function getInteractive(x:Float, y:Float):h2d.Interactive;
	@:dox(hide)
	@:noCompletion
	function dispatchEvent(event:hxd.Event, to:hxd.SceneEvents.Interactive):Void;
	@:dox(hide)
	@:noCompletion
	function handleEvent(event:hxd.Event, last:hxd.SceneEvents.Interactive):hxd.SceneEvents.Interactive;
	/**
		
				Add an event listener that will capture all events that were not caught by an `h2d.Interactive`
			
	**/
	function addEventListener(f:hxd.Event -> Void):Void;
	/**
		
				Remove a previously added event listener, returns false it was not part of the event listeners.
			
	**/
	function removeEventListener(f:hxd.Event -> Void):Bool;
	/**
		
				Starts input events capture and redirects them to `onEvent` method until `Scene.stopDrag` is called.
		
				While the method name may imply that only mouse events would be captured: This is not the case,
				as it will also capture all other input events, including keyboard events.
		
				@param onEvent A callback method that receives `hxd.Event` when input event happens.
				Unless `onEvent` sets `Event.propagate` to `true`, event won't be sent to other Interactives.
				@param onCancel An optional callback that is invoked when `Scene.stopDrag` is called.
				@param refEvent For touch events, when defined, only capture events that match the reference `Event.touchId`.
			
	**/
	function startCapture(onEvent:hxd.Event -> Void, ?onCancel:() -> Void, ?touchId:Int):Void;
	/**
		
				Stops current input event capture.
			
	**/
	function stopCapture():Void;
	/**
		
				Get the currently focused Interactive.
			
	**/
	function getFocus():h2d.Interactive;
	/**
		
				Dispose the scene and all its children, freeing used GPU memory.
		
				If Scene was allocated, causes `Object.onRemove` on all Scene objects.
			
	**/
	function dispose():Void;
	/**
		
				<span class="label">Internal usage</span>
		
				Before `Scene.render` or `Scene.sync` are called, allows to set how much time has elapsed (in seconds) since the last frame in order to update scene animations.
				This is managed automatically by hxd.App.
			
	**/
	function setElapsedTime(v:Float):Void;
	/**
		
				Synchronize the scene without rendering, updating all objects and animations by the given amount of time, in seconds.
			
	**/
	function syncOnly(et:Float):Void;
	/**
		
				<span class="label">Internal usage</span>
		
				Render the scene on the screen.
			
	**/
	function render(engine:h3d.Engine):Void;
	function mark(name:String):Void;
	/**
		
				Capture the scene into a texture and returns the resulting `h2d.Bitmap`.
		
				@param target Optional Tile to render onto. If not set, new Texture with interval Scene viewport dimensions is allocated,
				otherwise Tile boundaries and Texture are used.
			
	**/
	function captureBitmap(?target:h2d.Tile):h2d.Bitmap;
}