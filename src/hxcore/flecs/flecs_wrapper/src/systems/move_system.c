#include "flecs.h"

#include "../components/position.h"
#include "../components/velocity.h"

void MoveSystem(ecs_iter_t *it) {
    Position *p = ecs_field(it, Position, 0);
    Velocity *v = ecs_field(it, Velocity, 1);

    /* Print the set of components for the iterated over entities */
    //char *type_str = ecs_table_str(it->world, it->table);
    //printf("Move entities with [%s]\n", type_str);
    //ecs_os_free(type_str);

    /* Iterate entities for the current table */
    for (int i = 0; i < it->count; i ++) {

        if (v[i].x == 0 && v[i].y == 0) {
            // no velocity, early out
            continue;
        }

        //printf("Moving entity %s\n", ecs_get_name(it->world, it->entities[i]));
        ecs_set(it->world, it->entities[i], Position, {p[i].x + v[i].x, p[i].y + v[i].y});

    }
}