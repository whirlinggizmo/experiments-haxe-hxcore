#include <cstdio>
#include "hxcore.h"

// Optional: An exception callback to log Haxe exceptions.
void onHaxeException(const char* error) {
    std::fprintf(stderr, "Haxe exception: %s\n", error);
}

int main(int argc, char** argv) {
    // Start the Haxe runtime.
    hxcore_initializeHaxeThread(onHaxeException);

    // If you need to create an instance and call methods manually, for example:
    HaxeString scriptDir = "scripts";
    HaxeString srcDir = NULL; //"scripts/src";
    HaxeObject instance = hxcore_ScriptTest_new(scriptDir, NULL);
    hxcore_releaseHaxeString(scriptDir);
    hxcore_releaseHaxeString(srcDir);
    //hxcore_ScriptTest_tick(instance, 0.016); // call tick() with a deltaTime value or 
    for (int i = 0; i < 100; i++) {
        hxcore_ScriptTest_update(instance);      // call update() (calls tick(), but manages delta time itself)
    }
    hxcore_ScriptTest_destroy(instance);       // destroy the instance when done
    hxcore_releaseHaxeObject(instance);

    // When finished, stop the Haxe runtime.
    hxcore_stopHaxeThreadIfRunning(true);

    return 0;
}
