#include "flecs.h"

#include "systems/destination_system.h"
#include "systems/move_system.h"
#include "flecs_wrapper_component.h"
#include "flecs_wrapper_components.h"
#include "flecs_wrapper_world.h" 


ecs_world_t *world = NULL;


ecs_world_t *init_world() {
    world = ecs_init();

    REGISTER_COMPONENT(world, Position);
    REGISTER_COMPONENT(world, Velocity);
    REGISTER_COMPONENT(world, Destination);

    ECS_SYSTEM(world, DestinationSystem, EcsOnUpdate, Position, Velocity, Destination);
    ECS_SYSTEM(world, MoveSystem, EcsOnUpdate, Position, Velocity);

    return world;
}
    
