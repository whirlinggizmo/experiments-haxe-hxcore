// flecs_wrapper_component.h
#ifndef FLECS_WRAPPER_COMPONENT_H
#define FLECS_WRAPPER_COMPONENT_H

#include <stdio.h>
#include <string.h>
#include <flecs.h>

#ifdef __cplusplus
extern "C"
{
#endif

#define MAX_COMPONENTS 256

    typedef struct ComponentInfo
    {
        ecs_entity_t ecs_id;
        uint32_t id;
        char name[32];
        size_t size;
    } ComponentInfo;

    extern uint32_t component_info_count;
    extern ComponentInfo component_info_table[];
    
    void component_ecs_hash_insert(ecs_entity_t ecs_id, uint32_t id);
    void component_name_hash_insert(const char *name, uint32_t id);
    const ComponentInfo *get_component_info(uint32_t component_id);

    const ComponentInfo *get_component_info_by_name(const char *name);

    uint32_t get_component_id(ecs_entity_t ecs_id);

    uint32_t get_component_id_by_name(const char *name);

    const ecs_entity_t get_component_ecs_id(uint32_t component_id);

    const ecs_entity_t get_component_ecs_id_by_name(const char *name);

    const uint32_t get_component_size(uint32_t component_id);

    const uint32_t get_component_size_by_ecs_id(ecs_entity_t ecs_id);
    
    void clear_component_info();

#define REGISTER_COMPONENT(world, Type)                                                                     \
    do                                                                                                      \
    {                                                                                                       \
        if (component_info_count >= MAX_COMPONENTS)                                                         \
        {                                                                                                   \
            fprintf(stderr, "Unable to register component: %s (Reached MAX_COMPONENTS)\n", #Type);          \
            break;                                                                                          \
        }                                                                                                   \
        ECS_COMPONENT_DEFINE(world, Type);                                                                  \
        component_info_table[component_info_count].ecs_id = ecs_id(Type);                                   \
        strcpy(component_info_table[component_info_count].name, #Type);                                     \
        component_info_table[component_info_count].size = sizeof(Type);                                     \
        component_info_table[component_info_count].id = component_info_count;                               \
        component_ecs_hash_insert(component_info_table[component_info_count].ecs_id, component_info_count); \
        component_name_hash_insert(#Type, component_info_count);                                            \
        component_info_count++;                                                                             \
    } while (0)

#ifdef __cplusplus
}
#endif

#endif // FLECS_WRAPPER_COMPONENT_H