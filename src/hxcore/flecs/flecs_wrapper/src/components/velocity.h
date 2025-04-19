//components.velocity.h
#ifndef VELOCITY_H
#define VELOCITY_H

#include "flecs.h"

typedef struct Velocity {
    float x;
    float y;
} Velocity;

extern ECS_COMPONENT_DECLARE(Velocity);

#endif // VELOCITY_H