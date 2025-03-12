package core.ecs;


typedef EntityID = Int; 

/**
 * Generates unique EntityIDs for actors and components.
 */
class EIDGenerator {
    static private var currentEID:EntityID = 0;

    /**
     * Generates the next unique EntityID.
     * @return A unique EntityID.
     */
    static public function nextEID():EntityID {
        var id:EntityID = currentEID++;
        #if debug
        Log.debug('Generated new EntityID: $id');
        #end
        return id;
    }

    /**
     * Resets the EID counter. Use with caution!
     * Typically used in testing scenarios.
     */
    static public function reset():Void {
        #if debug
        trace('Resetting EntityID counter.');
        #end
        currentEID = 0;
    }
}
