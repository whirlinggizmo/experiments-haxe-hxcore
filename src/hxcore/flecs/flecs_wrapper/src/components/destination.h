#ifndef DESTINATION_H
#define DESTINATION_H

#include "flecs.h"

typedef struct Destination {
    float x;
    float y;
    float speed;
} Destination;

extern ECS_COMPONENT_DECLARE(Destination);

#endif