#ifndef POSITION_H
#define POSITION_H

//#include "flecs.h"

//#include "component_macros.h"

typedef struct Position {
    float x;
    float y;
} Position;

extern ECS_COMPONENT_DECLARE(Position);

#endif