#include "flecs.h"

#include "../components/position.h"
#include "../components/velocity.h"
#include "../components/destination.h"

#include <math.h>

static inline bool vec2_equals_with_epsilon(float ax, float ay, float bx, float by, float epsilon) {
    return fabsf(ax - bx) < epsilon && fabsf(ay - by) < epsilon;
}

void DestinationSystem(ecs_iter_t *it)
{
    Position *p = ecs_field(it, Position, 0);
    //Velocity *v = ecs_field(it, Velocity, 1);
    Destination *d = ecs_field(it, Destination, 2);

    for (int i = 0; i < it->count; i++)
    {
        //printf("In destination system for entity %d\n", (uint32_t)(it->entities[i] & ECS_ENTITY_MASK));

        // remove destination changed
        //ecs_remove(it->world, it->entities[i], DestinationChanged);

        // Cancel movement if speed is invalid
        if (d[i].speed <= 0) {
            printf("Speed is invalid for entity %d\n", (uint32_t)(it->entities[i] & ECS_ENTITY_MASK));
            ecs_remove(it->world, it->entities[i], Destination);
            ecs_set(it->world, it->entities[i], Velocity, {0, 0});
            continue;
        }

        // Already at the destination (within epsilon)
        if (vec2_equals_with_epsilon(p[i].x, p[i].y, d[i].x, d[i].y, 0.01f)) {
            // Snap directly to destination
            ecs_set(it->world, it->entities[i], Position, {d[i].x, d[i].y});
            ecs_set(it->world, it->entities[i], Velocity, {0, 0});
            ecs_remove(it->world, it->entities[i], Destination);
            continue;
        }

        // Direction vector toward destination
        float dx = d[i].x - p[i].x;
        float dy = d[i].y - p[i].y;
        float dist_sq = dx * dx + dy * dy;

        // Normalize direction
        float length = sqrtf(dist_sq);

        // Prevent divide by zero
        if (length < 0.0001f) {
            ecs_set(it->world, it->entities[i], Velocity, {0, 0});
            ecs_remove(it->world, it->entities[i], Destination);
            continue;
        }

        // Compute scaled velocity
        float vx = dx / length * d[i].speed;
        float vy = dy / length * d[i].speed;

        float vel_sq = vx * vx + vy * vy;

        // Will this velocity overshoot?
        if (vel_sq >= dist_sq) {
            // Snap directly to destination
            ecs_set(it->world, it->entities[i], Position, {d[i].x, d[i].y});
            ecs_set(it->world, it->entities[i], Velocity, {0, 0});
            ecs_remove(it->world, it->entities[i], Destination);
            continue;
        }

        // Otherwise apply computed velocity
        ecs_set(it->world, it->entities[i], Velocity, {vx, vy});
    }
}
