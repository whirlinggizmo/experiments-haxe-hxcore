// lib/flecs_wrapper/src/flecs_wrapper.c
#define FLECS_OBSERVER

#include <stdlib.h>
#include "flecs.h"
#include "flecs_wrapper.h"

// defined in flecs_wrapper.c 
extern ecs_world_t *world;


// components
#include "components/position.h"
#include "components/velocity.h"
#include "components/destination.h"

// entity
#define MAX_ENTITIES 65536
static ecs_entity_t entity_ecs_id_table[MAX_ENTITIES] = {0};
static uint32_t entity_ecs_id_count = 1; // reserved index 0 for unknown
// Hash table: ecs_entity_t -> entity_id
#define ENTITY_HASH_SIZE MAX_ENTITIES * 2 // 2x MAX_ENTITIES for good load factor
static ecs_entity_t entity_hash_keys[ENTITY_HASH_SIZE] = {0};
static int32_t entity_hash_values[ENTITY_HASH_SIZE] = {0};


static inline uint32_t hash_entity(ecs_entity_t id)
{
    return (uint32_t)(id * 2654435761u) & (ENTITY_HASH_SIZE - 1);
}

static void entity_hash_insert(ecs_entity_t ecs_id, int32_t entity_id)
{
    uint32_t index = hash_entity(ecs_id);
    while (entity_hash_keys[index] != 0)
    {
        index = (index + 1) & (ENTITY_HASH_SIZE - 1);
    }
    entity_hash_keys[index] = ecs_id;
    entity_hash_values[index] = entity_id;
}

int32_t get_entity_id(ecs_entity_t ecs_id)
{
    uint32_t index = hash_entity(ecs_id);
    while (entity_hash_keys[index] != 0)
    {
        if (entity_hash_keys[index] == ecs_id)
            return entity_hash_values[index];
        index = (index + 1) & (ENTITY_HASH_SIZE - 1);
    }
    return 0;
}

ecs_entity_t get_entity_ecs_id(int32_t id)
{
    if ((uint32_t)id < entity_ecs_id_count)
        return entity_ecs_id_table[id];
    return 0;
}

uint32_t set_entity_id(uint32_t entity_id, ecs_entity_t entity_ecs_id)
{
    if ((entity_id < 1) || (entity_id >= MAX_ENTITIES))
    {
        fprintf(stderr, "Unable to set ecs_id for entity_id, (out of range 1..%u) %u\n", MAX_ENTITIES - 1, entity_id);
        return 0;
    }
    if (entity_ecs_id_table[entity_id] != 0)
    {
        fprintf(stderr, "Unable to set ecs_id for entity_id %u, already set (currently %lu)\n", entity_id, entity_ecs_id_table[entity_id]);
        return 0;
    }
    entity_ecs_id_table[entity_id] = entity_ecs_id;
    // entity_reverse_id_table[entity_ecs_id] = entity_id;
    return entity_id;
}


static uint32_t create_entity(const char *name)
{
    if (entity_ecs_id_count >= MAX_ENTITIES)
    {
        fprintf(stderr, "Could not create entity (max entities reached: %u)\n", MAX_ENTITIES);
        return 0;
    }

    uint32_t id = entity_ecs_id_count;

    // Sanity check
    if (entity_ecs_id_table[id] != 0)
    {
        fprintf(stderr, "The current entity index (%u) is not empty. This shouldn't happen!\n", id);
        return 0;
    }

    ecs_entity_t entity_ecs_id = ecs_entity(world, {.name = name});

    entity_ecs_id_table[id] = entity_ecs_id;        // forward mapping
    entity_hash_insert(entity_ecs_id, (int32_t)id); // reverse mapping

    entity_ecs_id_count++;
    return id;
}

bool destroy_entity(uint32_t entity_id)
{
    ecs_entity_t entity_ecs_id = get_entity_ecs_id(entity_id);
    if (entity_ecs_id == 0)
    {
        fprintf(stderr, "Could not destroy entity_id %u (entity does not exist)\n", entity_id);
        return false;
    }
    ecs_delete(world, entity_ecs_id);
    entity_ecs_id_table[entity_id] = 0;
    // minor optimization: if the entity happened to be the last one in our entity_ecs_id_table, we shrink it
    if (entity_id == entity_ecs_id_count - 1)
    {
        entity_ecs_id_count--;
    }
    return true;
}



EXPORT uint32_t flecs_entity_create(const char *name)
{
    return create_entity(name);
}

EXPORT bool flecs_entity_destroy(uint32_t entity_id)
{
    return destroy_entity(entity_id);
}
