
/**
 * Basic example script.  
 * 
 * All Scripts are stateless, with the exception of the context object (ctx) that is passed by its host and persisted between reloads.
 * 
 */

class Basic extends Script {

    /**
     * onLoad()
     * This is called when the script is initially loaded, only once during its lifecycle.
     * 
     * Note that this will NOT be called if the script is reloaded.
     */

    override public function onLoad() {
        log("Basic.onLoad");
    }

    /**
     * Called when the script is unloaded (e.g. when the entity is about to be reloaded or destroyed)
     */
    override public function onUnload() {
    
        log("Basic.onUnload");
    }

    /**
     *  Called when the script is updated.  onUnload() is called before the script is reloaded, allowing you to stash things in the context (ctx) object.
     */
    override public function onReload() {
        log("Basic.onReload");
    }
}