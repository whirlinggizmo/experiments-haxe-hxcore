// lib/flecs_wrapper/src/flecs_wrapper_component.c
#define FLECS_OBSERVER

#include <stdlib.h>
#include "flecs_wrapper.h"
#include "flecs_wrapper_component.h"
#include "flecs_wrapper_entity.h"

// components
#include "flecs_wrapper_components.h"

#include "flecs_wrapper_world.h" // for world access


// Lookup tables:

#define COMPONENT_HASH_SIZE (MAX_COMPONENTS * 2) // double the size of the hash

ComponentInfo component_info_table[MAX_COMPONENTS] = {0};
uint32_t component_info_count = 1; // reserved index 0 for unknown

static ecs_entity_t component_ecs_id_keys[COMPONENT_HASH_SIZE] = {0};
static uint32_t component_ecs_id_values[COMPONENT_HASH_SIZE] = {0};

static char component_name_keys[COMPONENT_HASH_SIZE][32] = {{0}};
static uint32_t component_name_values[COMPONENT_HASH_SIZE] = {0};

static uint32_t hash_u64(uint64_t val)
{
    return (uint32_t)(val * 2654435761u);
}

static uint32_t hash_str(const char *str)
{
    // FNV-1a hash for strings
    uint32_t hash = 2166136261u;
    while (*str)
    {
        hash ^= (uint8_t)(*str++);
        hash *= 16777619u;
    }
    return hash;
}

void component_ecs_hash_insert(ecs_entity_t ecs_id, uint32_t id)
{
    uint32_t i = hash_u64(ecs_id) & (COMPONENT_HASH_SIZE - 1);
    while (component_ecs_id_keys[i] != 0)
    {
        i = (i + 1) & (COMPONENT_HASH_SIZE - 1);
    }
    component_ecs_id_keys[i] = ecs_id;
    component_ecs_id_values[i] = id;
}

void component_name_hash_insert(const char *name, uint32_t id)
{
    uint32_t i = hash_str(name) & (COMPONENT_HASH_SIZE - 1);
    while (component_name_keys[i][0] != '\0')
    {
        i = (i + 1) & (COMPONENT_HASH_SIZE - 1);
    }
    strncpy(component_name_keys[i], name, 31);
    component_name_values[i] = id;
}

const ComponentInfo *get_component_info(uint32_t component_id)
{
    if (component_id == 0 || component_id >= component_info_count)
    {
        fprintf(stderr, "Unable to get component_info for component_id %u (out of range 1..%u)\n", component_id, component_info_count - 1);
        return NULL;
    }
    return &component_info_table[component_id];
}

const ComponentInfo *get_component_info_by_name(const char *name)
{
    if (name == NULL || strlen(name) == 0)
    {
        fprintf(stderr, "Unable to get component_info by name (name is empty or null)\n");
        return NULL;
    }
    for (uint32_t i = 1; i < component_info_count; ++i)
    {
        if (strcmp(component_info_table[i].name, name) == 0)
        {
            return &component_info_table[i];
        }
    }
    fprintf(stderr, "Unable to get component_info for name %s (not found)\n", name);
    return NULL;
}

uint32_t get_component_id(ecs_entity_t ecs_id)
{
    uint32_t i = hash_u64(ecs_id) & (COMPONENT_HASH_SIZE - 1);
    while (component_ecs_id_keys[i] != 0)
    {
        if (component_ecs_id_keys[i] == ecs_id)
            return component_ecs_id_values[i];
        i = (i + 1) & (COMPONENT_HASH_SIZE - 1);
    }
    fprintf(stderr, "Unable to get component_id for ecs_id %lu (not found)\n", ecs_id);
    return 0;
}

uint32_t get_component_id_by_name(const char *name)
{
    uint32_t i = hash_str(name) & (COMPONENT_HASH_SIZE - 1);
    while (component_name_keys[i][0] != '\0')
    {
        if (strcmp(component_name_keys[i], name) == 0)
            return component_name_values[i];
        i = (i + 1) & (COMPONENT_HASH_SIZE - 1);
    }
    return 0;
}

const ecs_entity_t get_component_ecs_id(uint32_t component_id)
{
    if ((component_id < 1) || (component_id >= component_info_count))
    {
        fprintf(stderr, "Unable to get ecs_id for component_id %u (out of range 1..%u)\n", component_id, component_info_count - 1);
        return 0;
    }
    return component_info_table[component_id].ecs_id;
}

const ecs_entity_t get_component_ecs_id_by_name(const char *name)
{
    const ComponentInfo *component_info = get_component_info_by_name(name);
    if (component_info)
    {
        return component_info->ecs_id;
    }

    fprintf(stderr, "Unable to get component_ecs_id for name %s \n", name);

    return 0;
}

const uint32_t get_component_size(uint32_t component_id)
{
    if ((component_id < 1) || (component_id >= component_info_count))
    {
        fprintf(stderr, "Unable to get size for component_id %u (out of range 1..%u)\n", component_id, component_info_count - 1);
        return 0;
    }
    return component_info_table[component_id].size;
}


const uint32_t get_component_size_by_ecs_id(ecs_entity_t ecs_id)
{
    uint32_t component_id = get_component_id(ecs_id);
    return get_component_size(component_id);
}

void clear_component_info_table()
{
    component_info_count = 1;
    memset(component_info_table, 0, sizeof(component_info_table));
    memset(component_ecs_id_keys, 0, sizeof(component_ecs_id_keys));
    memset(component_ecs_id_values, 0, sizeof(component_ecs_id_values));
    memset(component_name_keys, 0, sizeof(component_name_keys));
    memset(component_name_values, 0, sizeof(component_name_values));
}

bool set_entity_component_data(uint32_t entity_id, uint32_t component_id, const void *component_data_ptr)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;
    const ComponentInfo *component_info = get_component_info(component_id);
    if (!component_info)
        return false;
    ecs_set_id(world, entity_ecs_id, component_info->ecs_id, component_info->size, component_data_ptr);
    return true;
}

const void* get_entity_component_data(uint32_t entity_id, uint32_t component_id)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return NULL;
    const ComponentInfo *component_info = get_component_info(component_id);
    if (!component_info)
        return NULL;
    const void *component_data = ecs_get_id(world, entity_ecs_id, component_info->ecs_id);
    return component_data;
}

///////////////////////////////////////////////////////////////

EXPORT int32_t flecs_component_get_id_by_name(const char *name)
{
    if (name == NULL)
        return 0;

    for (uint32_t i = 1; i < component_info_count; ++i)
    {
        if (strcmp(component_info_table[i].name, name) == 0)
        {
            return i;
        }
    }
    return 0;
}

EXPORT bool flecs_component_is_mark_changed_by_name(uint32_t entity_id, const char *component_name)
{
    int32_t id = get_component_id_by_name(component_name);
    if (id < 1)
        return false;
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (!entity_ecs_id)
        return false;
    ecs_add_id(world, entity_ecs_id, component_info_table[id].ecs_id);
    return true;
}

EXPORT bool flecs_component_is_marked_changed(uint32_t entity_id, uint32_t component_id)
{
    if (component_id < 1 || component_id >= component_info_count)
        return false;
    if (component_info_table[component_id].ecs_id == 0)
        return false;
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (!entity_ecs_id)
        return false;
    ecs_add_id(world, entity_ecs_id, component_info_table[component_id].ecs_id);
    return true;
}

EXPORT bool flecs_component_is_tag(uint32_t component_id)
{
    const ComponentInfo *component_info = get_component_info(component_id);
    return component_info && component_info->size == 0;
}

EXPORT void flecs_component_print_registry(void)
{
    printf("Registered components (%u):\n", component_info_count - 1);
    for (uint32_t i = 1; i < component_info_count; ++i)
    {
        printf("  [%u] %s (size: %zu)\n", i, component_info_table[i].name, component_info_table[i].size);
    }
}

EXPORT void flecs_entity_print_components(uint32_t entity_id)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return;
    printf("Entity %u has components:\n", entity_id);
    for (uint32_t i = 1; i < component_info_count; ++i)
    {
        if (ecs_has_id(world, entity_ecs_id, component_info_table[i].ecs_id))
        {
            printf("  [%u] %s\n", i, component_info_table[i].name);
        }
    }
}

EXPORT bool flecs_entity_has_component(uint32_t entity_id, uint32_t component_id)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;
    const ComponentInfo *component_info = get_component_info(component_id);
    if (!component_info)
    {
        fprintf(stderr, "Unable to get component_info for entity_id %u and component_id %u\n", entity_id, component_id);
        return false;
    }
    return ecs_has_id(world, entity_ecs_id, component_info->ecs_id);
}

EXPORT bool flecs_entity_has_component_by_name(uint32_t entity_id, const char *component_name)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;
    const ComponentInfo *component_info = get_component_info_by_name(component_name);
    if (!component_info)
        return false;
    return ecs_has_id(world, entity_ecs_id, component_info->ecs_id);
}

EXPORT bool flecs_entity_add_component(uint32_t entity_id, uint32_t component_id)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;
    const ComponentInfo *component_info = get_component_info(component_id);
    if (!component_info)
        return false;
    char zero[component_info->size];          /* automatic array, correct size */
    memset(zero, 0, component_info->size);
    ecs_set_id(world, entity_ecs_id, component_info->ecs_id, component_info->size, (const void *)&zero);
    //printf("Added component %s to entity %u (size: %zu)\n", component_info->name, entity_id, component_info->size);
    return true;
}

EXPORT bool flecs_entity_add_component_by_name(uint32_t entity_id, const char *component_name)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;
    const ComponentInfo *component_info = get_component_info_by_name(component_name);
    if (!component_info)
        return false;
    char zero[component_info->size];          /* automatic array, correct size */
    memset(zero, 0, component_info->size);
    ecs_set_id(world, entity_ecs_id, component_info->ecs_id, component_info->size, (const void *)&zero);
    //printf("Added component %s to entity %u (size: %zu)\n", component_info->name, entity_id, component_info->size);
    return true;
}

EXPORT bool flecs_entity_remove_component(uint32_t entity_id, uint32_t component_id)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;
    const ComponentInfo *component_info = get_component_info(component_id);
    if (!component_info)
        return false;
    ecs_remove_id(world, entity_ecs_id, component_info->ecs_id);
    return true;
}

EXPORT bool flecs_entity_remove_component_by_name(uint32_t entity_id, const char *component_name)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;
    const ComponentInfo *component_info = get_component_info_by_name(component_name);
    if (!component_info)
        return false;
    ecs_remove_id(world, entity_ecs_id, component_info->ecs_id);
    return true;
}

EXPORT bool flecs_entity_set_component_data(uint32_t entity_id, uint32_t component_id, const void *component_data_ptr)
{
   return set_entity_component_data(entity_id, component_id, component_data_ptr);
}

EXPORT const void* flecs_entity_get_component_data(uint32_t entity_id, uint32_t component_id)
{
    return get_entity_component_data(entity_id, component_id);
}

// component helpers
// TODO:  Move them into their respective component files (i.e. velocity.c, position.c, etc.)

EXPORT bool flecs_entity_set_velocity(uint32_t entity_id, float x, float y)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;
    ecs_set(world, entity_ecs_id, Velocity, {x, y});
    return true;
}

EXPORT bool flecs_entity_get_velocity(uint32_t entity_id, float *x, float *y)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;

    if (!ecs_has(world, entity_ecs_id, Velocity))
    {
        fprintf(stderr, "Entity %u has no velocity component\n", entity_id);
        return false;
    }

    const Velocity *vel = ecs_get(world, entity_ecs_id, Velocity);
    *x = vel->x;
    *y = vel->y;
    return true;
}

EXPORT bool flecs_entity_set_position(uint32_t entity_id, float x, float y)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;

    ecs_set(world, entity_ecs_id, Position, {x, y});
    return true;
}

EXPORT bool flecs_entity_get_position(uint32_t entity_id, float *x, float *y)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;

    if (!ecs_has(world, entity_ecs_id, Position))
    {
        fprintf(stderr, "Entity %u has no position component\n", entity_id);
        return false;
    }

    const Position *pos = ecs_get(world, entity_ecs_id, Position);
    *x = pos->x;
    *y = pos->y;
    return true;
}

EXPORT bool flecs_entity_set_destination(uint32_t entity_id, float x, float y, float speed)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;
    ecs_set(world, entity_ecs_id, Destination, {x, y, speed});
    return true;
}

EXPORT bool flecs_entity_get_destination(uint32_t entity_id, float *x, float *y, float *speed)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;
    if (!ecs_has(world, entity_ecs_id, Destination))
    {
        fprintf(stderr, "Entity %u has no destination component\n", entity_id);
        return false;
    }
    const Destination *dest = ecs_get(world, entity_ecs_id, Destination);
    *x = dest->x;
    *y = dest->y;
    *speed = dest->speed;
    return true;
}

// trying out a generic set component function for components that are vector2 of floats.
EXPORT bool flecs_entity_set_component_vec2(uint32_t entity_id, uint32_t component_id, float x, float y)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;

    const ComponentInfo *component_info = get_component_info(component_id);
    if (!component_info)
    {
        fprintf(stderr, "Invalid component ID: %d\n", component_id);
        return false;
    }

    void *comp = ecs_get_mut_id(world, entity_ecs_id, component_info->ecs_id);
    if (!comp)
    {
        fprintf(stderr, "Failed to get component: %s\n", component_info->name);
        return false;
    }

    if (component_info->size != sizeof(float) * 2)
    {
        fprintf(stderr, "Component size mismatch: %s\n", component_info->name);
        return false;
    }

    float *values = (float *)comp;
    if (values[0] == x && values[1] == y)
        return true;

    values[0] = x;
    values[1] = y;

    // be sure to tag it as modified for observers
    ecs_modified_id(world, entity_ecs_id, component_info->ecs_id);

    return true;
}

EXPORT bool flecs_entity_get_component_vec2(uint32_t entity_id, uint32_t component_id, float *x, float *y)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
        return false;

    const ComponentInfo *component_info = get_component_info(component_id);
    if (!component_info)
    {
        fprintf(stderr, "Invalid component ID: %d\n", component_id);
        return false;
    }

    if (!ecs_has_id(world, entity_ecs_id, component_info->ecs_id))
    {
        fprintf(stderr, "Entity %u has no %s component\n", entity_id, component_info->name);
        return false;
    }

    const void *comp = ecs_get_id(world, entity_ecs_id, component_info->ecs_id);
    if (!comp)
    {
        fprintf(stderr, "Failed to get component: %s\n", component_info->name);
        return false;
    }

    if (component_info->size != sizeof(float) * 2)
    {
        fprintf(stderr, "Component size mismatch: %s\n", component_info->name);
        return false;
    }

    float *values = (float *)comp;
    *x = values[0];
    *y = values[1];
    return true;
}
