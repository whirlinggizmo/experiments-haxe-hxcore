// destination_system.c
#include "flecs.h"

#include "flecs_wrapper_components.h"
#include "systems/destination_system.h"

#include <math.h>

#define DEST_EPSILON 0.01f
#define MIN_MOVE_DISTANCE 0.0001f

void DestinationSystem(ecs_iter_t *it) {
    Position *p = ecs_field(it, Position, 0);
    Destination *d = ecs_field(it, Destination, 2);

    for (int i = 0; i < it->count; i++) {

        // early out, before we bother calculating distance
        if (d[i].speed <= 0.0f) {
            ecs_set(it->world, it->entities[i], Position, {d[i].x, d[i].y});
            ecs_set(it->world, it->entities[i], Velocity, {0, 0});
            ecs_remove(it->world, it->entities[i], Destination);
            //printf("d[i].speed <= 0.0f\n");
            continue;
        }

        float dx = d[i].x - p[i].x;
        float dy = d[i].y - p[i].y;
        float distance = sqrtf(dx * dx + dy * dy);

        if (distance <= DEST_EPSILON) {
            ecs_set(it->world, it->entities[i], Position, {d[i].x, d[i].y});
            ecs_set(it->world, it->entities[i], Velocity, {0, 0});
            ecs_remove(it->world, it->entities[i], Destination);
            //printf("distance <= DEST_EPSILON\n");
            continue;
        }

        if (distance < MIN_MOVE_DISTANCE) {
            ecs_set(it->world, it->entities[i], Velocity, {0, 0});
            ecs_set(it->world, it->entities[i], Position, {d[i].x, d[i].y});
            ecs_remove(it->world, it->entities[i], Destination);
            //printf("distance < MIN_MOVE_DISTANCE\n");
            continue;
        }

        float vx = dx / distance * d[i].speed;
        float vy = dy / distance * d[i].speed;

        float step_distance = it->delta_time * d[i].speed;

        if (step_distance >= distance) {
            ecs_set(it->world, it->entities[i], Position, {d[i].x, d[i].y});
            ecs_set(it->world, it->entities[i], Velocity, {0, 0});
            ecs_remove(it->world, it->entities[i], Destination);
            //printf("step_distance >= distance\n");
        } else {
            ecs_set(it->world, it->entities[i], Velocity, {vx, vy});
        }
    }
}
