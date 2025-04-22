#pragma once

#include "flecs.h"

//
// NOTE:Don't forget to update flecs_wrapper_components.c for the actual component declarations
//

typedef struct Destination {
    float x;
    float y;
    float speed;
} Destination;
extern ECS_COMPONENT_DECLARE(Destination);

typedef struct Position {
    float x;
    float y;
} Position;
extern ECS_COMPONENT_DECLARE(Position);

typedef struct Velocity {
    float x;
    float y;
} Velocity;
extern ECS_COMPONENT_DECLARE(Velocity);