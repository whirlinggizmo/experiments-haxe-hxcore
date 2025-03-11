package h3d.scene;

/**
 h3d.scene.Scene is the root class for a 3D scene. All root objects are added to it before being drawn on screen.
 */
/**
	
		h3d.scene.Scene is the root class for a 3D scene. All root objects are added to it before being drawn on screen.
	
**/
@:native("h3d.scene.Scene") extern class Scene extends h3d.scene.Object  {
	/**
		
				Create a new scene. A default 3D scene is already available in `hxd.App.s3d`
			
	**/
	function new(?createRenderer:Bool, ?createLightSystem:Bool):Void;
	/**
		
				The scene current camera.
			
	**/
	var camera : h3d.Camera;
	/**
		
				The scene light system. Can be customized.
			
	**/
	var lightSystem : h3d.scene.LightSystem;
	/**
		
				The scene renderer. Can be customized.
			
	**/
	var renderer(default, set) : h3d.scene.Renderer;
	var offsetX : Float;
	var offsetY : Float;
	var ratioX : Float;
	var ratioY : Float;
	/**
		
				Adjust the position of the ray used to handle interactives.
			
	**/
	var interactiveOffset : Float;
	@:noCompletion
	@:dox(hide)
	function setEvents(events:hxd.SceneEvents):Void;
	/**
		
				Add an event listener that will capture all events not caught by an h2d.Interactive
			
	**/
	function addEventListener(f:hxd.Event -> Void):Void;
	/**
		
				Remove a previously added event listener, return false it was not part of our event listeners.
			
	**/
	function removeEventListener(f:hxd.Event -> Void):Bool;
	@:dox(hide)
	@:noCompletion
	function dispatchListeners(event:hxd.Event):Void;
	private function set_renderer(r:h3d.scene.Renderer):h3d.scene.Renderer;
	@:dox(hide)
	@:noCompletion
	function dispatchEvent(event:hxd.Event, to:hxd.SceneEvents.Interactive):Void;
	@:dox(hide)
	@:noCompletion
	function isInteractiveVisible(i:hxd.SceneEvents.Interactive):Bool;
	@:dox(hide)
	@:noCompletion
	function handleEvent(event:hxd.Event, last:hxd.SceneEvents.Interactive):h3d.scene.Interactive;
	override function clone(?o:h3d.scene.Object):h3d.scene.Scene;
	/**
		
				Free the GPU memory for this Scene and its children
			
	**/
	function dispose():Void;
	/**
		
				Before render() or sync() are called, allow to set how much time has elapsed (in seconds) since the last frame in order to update scene animations.
				This is managed automatically by hxd.App
			
	**/
	function setElapsedTime(elapsedTime:Float):Void;
	/**
		
				Synchronize the scene without rendering, updating all objects and animations by the given amount of time, in seconds.
			
	**/
	function syncOnly(et:Float):Void;
	/**
		
				Perform a rendering with `RendererContext.computingStatic=true`, allowing the computation of static shadow maps, etc.
			
	**/
	function computeStatic():Void;
	/**
		
				Automatically called when the 3D context is lost
			
	**/
	function onContextLost():Void;
	/**
		
				Render the scene on screen. Internal usage only.
			
	**/
	@:access(h3d.mat.Pass)
	@:access(h3d.scene.RenderContext)
	function render(engine:h3d.Engine):Void;
	function mark(name:String):Void;
	/**
		
				Temporarily overrides the output render target. This is useful for picture-in-picture rendering,
				where the output render target has a different size from the window.
				`tex` must have a matching depthBuffer attached.
				Call `setOutputTarget()` after `render()` has been called.
			
	**/
	function setOutputTarget(?engine:h3d.Engine, ?tex:h3d.mat.Texture):Void;
}