// lib/flecs_wrapper/src/flecs_wrapper.c
#define FLECS_OBSERVER

#include <stdlib.h>
#include "flecs.h"
#include "flecs_wrapper.h"
#include "flecs_wrapper_component.h"

// components
#include "components/position.h"
#include "components/velocity.h"
#include "components/destination.h"

// systems
#include "systems/move_system.h"
#include "systems/destination_system.h"

ecs_world_t *world = NULL;


EXPORT const char *flecs_version(void)
{
    return FLECS_VERSION;
}

EXPORT void flecs_init()
{
    world = ecs_init();

    REGISTER_COMPONENT(world, Position);
    REGISTER_COMPONENT(world, Velocity);
    REGISTER_COMPONENT(world, Destination);

    //ECS_SYSTEM(world, DestinationSystem, EcsOnUpdate, Position, Velocity, Destination);

    //ECS_SYSTEM(world, MoveSystem, EcsOnUpdate, Position, Velocity);
}

EXPORT void flecs_progress(float delta_time)
{
    ecs_progress(world, delta_time);
}

EXPORT void flecs_fini()
{
    ecs_fini(world);
}