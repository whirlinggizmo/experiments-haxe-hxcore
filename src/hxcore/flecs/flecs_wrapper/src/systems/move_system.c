// move_system.c

#include "flecs.h"
#include "flecs_wrapper_components.h"
#include "systems/move_system.h"

void MoveSystem(ecs_iter_t *it) {
    //printf("MoveSystem called for %d entities\n", it->count);
    Position *p = ecs_field(it, Position, 0);
    Velocity *v = ecs_field(it, Velocity, 1);

    for (int i = 0; i < it->count; i++) {
        if (v[i].x == 0 && v[i].y == 0) {
           // continue; // no movement
        }

        float new_x = p[i].x + v[i].x * it->delta_time;
        float new_y = p[i].y + v[i].y * it->delta_time;

        ecs_set(it->world, it->entities[i], Position, { new_x, new_y });
    }
}
