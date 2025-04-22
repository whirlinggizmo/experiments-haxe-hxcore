// lib/flecs_wrapper/src/flecs_wrapper.c
#define FLECS_OBSERVER

#include "flecs.h"
#include "flecs_wrapper.h"
#include "flecs_wrapper_world.h"
#include "flecs_wrapper_event.h"

EXPORT const char *flecs_version(void)
{
    return FLECS_VERSION;
}

EXPORT void flecs_init()
{
    init_event_table();

    world = init_world();
    if (world == NULL)
    {
        fprintf(stderr, "Unable to initialize world\n");
        return;
    }
}

EXPORT void flecs_progress(float delta_time)
{
    if (world == NULL)
    {
        fprintf(stderr, "Unable to progress world (not initialized)\n");
        return;
    }
    ecs_progress(world, delta_time);
}

EXPORT void flecs_fini()
{
    if (world == NULL)
    {
        fprintf(stderr, "Unable to finalize world (not initialized)\n");
        return;
    }
    ecs_fini(world);
}