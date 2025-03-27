#include <cstdio>
#include "hxcore.h"
#include <unistd.h>


// Optional: An exception callback to log Haxe exceptions.
void onHaxeException(const char* error) {
    std::fprintf(stderr, "Haxe exception: %s\n", error);
}

int main(int argc, char** argv) {
    // Start the Haxe runtime.
    hxcore_initializeHaxeThread(onHaxeException);

    // If you need to create an instance and call methods manually, for example:
    HaxeString scriptDir = "scripts";
    HaxeString srcDir = "../../scripts";
    HaxeObject instance = hxcore_API_new(scriptDir, srcDir, true);
    hxcore_releaseHaxeString(scriptDir);
    hxcore_releaseHaxeString(srcDir);

    // create an entity
    int entityId = hxcore_API_createEntity(instance, "Test");

    // we can run the update loop
    hxcore_API_run(instance);
    sleep(50);
    // ... or pump update() manually
    /*
    bool quitFlag = hxcore_API_update(instance, 0.016); // call update() with a deltaTime value or...
    for (int i = 0; i < 250; i++) {
        quitFlag = hxcore_API_tick(instance);      // call tick() (which calls update(), but manages delta time itself)
        if (quitFlag) {
            break;
        }
    }
    */
    
    // destroy the entity
    hxcore_API_destroyEntity(instance, entityId);

    // tell the API we're done
    hxcore_API_quit(instance);
    // if we use run(), the API will cleanup for us. Otherwise, we need to do it manually
    //hxcore_API_destroy(instance);       // destroy the instance when done

    hxcore_releaseHaxeObject(instance);

    // When finished, stop the Haxe runtime.
    hxcore_stopHaxeThreadIfRunning(true);

    return 0;
}
