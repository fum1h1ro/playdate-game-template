#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <pd_api.h>
#include <external.h>

PlaydateAPI *api;

int eventHandler(PlaydateAPI *pd, PDSystemEvent event, uint32_t arg)
{
    if (event == kEventInit) {
        api = pd;
#if TARGET_SIMULATOR
        api->system->logToConsole("SIMULATOR");
#else
        api->system->logToConsole("DEVICE");
#endif
#ifdef NDEBUG
        api->system->logToConsole("RELEASE");
#else
        api->system->logToConsole("DEBUG");
#endif

        // external package
        int result = external_add(1, 2);
        api->system->logToConsole("external_add(1, 2) = %d", result);
    }

    if (event == kEventInitLua) {
    }

    if (event == kEventTerminate) {
    }

    if (event == kEventPause) {
    }

    return 0;
}

