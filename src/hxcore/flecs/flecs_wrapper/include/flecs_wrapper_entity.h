// flecs_wrapper_entity.h
#ifndef FLECS_WRAPPER_ENTITY_H
#define FLECS_WRAPPER_ENTITY_H

#include <flecs.h>

#ifdef __cplusplus
extern "C"
{
#endif

    int32_t get_entity_id(ecs_entity_t ecs_id);
    ecs_entity_t get_entity_ecs_id(int32_t id);
    uint32_t set_entity_id(uint32_t entity_id, ecs_entity_t entity_ecs_id);

#ifdef __cplusplus
}
#endif

#endif // FLECS_WRAPPER_ENTITY_H