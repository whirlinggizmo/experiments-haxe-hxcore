// lib/flecs_wrapper/src/flecs_wrapper.c
#define FLECS_OBSERVER

#include <stdlib.h>
#include "flecs.h"
#include "flecs_wrapper.h"
#include "flecs_wrapper_component.h"
#include "flecs_wrapper_entity.h"
#include "flecs_wrapper_event.h"


// there are fixed number of event types, so we'll just add them directly
#define event_ecs_id_count 8
static ecs_entity_t event_ecs_id_table[event_ecs_id_count] = { // lookup table for event_id -> event_ecs_id
    /*
    // Reference: Events, taken from flecs world.c  Note that the order matters, since it's used to index into the event_id_table
    const ecs_entity_t EcsOnAdd =                       FLECS_HI_COMPONENT_ID + 40;
    const ecs_entity_t EcsOnRemove =                    FLECS_HI_COMPONENT_ID + 41;
    const ecs_entity_t EcsOnSet =                       FLECS_HI_COMPONENT_ID + 42;
    const ecs_entity_t EcsOnDelete =                    FLECS_HI_COMPONENT_ID + 43;
    const ecs_entity_t EcsOnDeleteTarget =              FLECS_HI_COMPONENT_ID + 44;
    const ecs_entity_t EcsOnTableCreate =               FLECS_HI_COMPONENT_ID + 45;
    const ecs_entity_t EcsOnTableDelete =               FLECS_HI_COMPONENT_ID + 46;
    */
    0,                          // leave starting index 0 empty for unknown
    FLECS_HI_COMPONENT_ID + 40, // EcsOnAdd
    FLECS_HI_COMPONENT_ID + 41, // EcsOnRemove
    FLECS_HI_COMPONENT_ID + 42, // EcsOnSet
    FLECS_HI_COMPONENT_ID + 43, // EcsOnDelete
    FLECS_HI_COMPONENT_ID + 44, // EcsOnDeleteTarget
    FLECS_HI_COMPONENT_ID + 45, // EcsOnTableCreate
    FLECS_HI_COMPONENT_ID + 46, // EcsOnTableDelete
};

uint32_t get_event_id(const ecs_entity_t ecs_id)
{
    // We could use something like hash_u64, but with only 8 events, the hashing is probably slower than a linear search
    for (uint32_t i = 1; i < event_ecs_id_count; ++i)
    {
        if (event_ecs_id_table[i] == ecs_id)
        {
            return i;
        }
    }
    fprintf(stderr, "Unable to get event_id for ecs_id %lu (not found)\n", ecs_id);
    return 0;
}
ecs_entity_t get_event_ecs_id(uint32_t event_id)
{
    if (event_id < 1 || (event_id >= event_ecs_id_count))
    {
        fprintf(stderr, "Unable to get ecs_id for event_id %u (out of range 1..%u)\n", event_id, event_ecs_id_count - 1);
        return 0;
    }
    return event_ecs_id_table[event_id];
}

// observer
typedef struct ObserverCallbackContext
{
    ObserverCallback callback;
    uint32_t callback_id;
} ObserverCallbackContext;

// A simple static callback that is registered with flecs observers.
static void on_observed_component_changed(ecs_iter_t *it)
{
    // printf("Observer callback invoked for %d entities\n", it->count);
    for (int i = 0; i < it->count; i++)
    {
        uint32_t entity_id = get_entity_id(it->entities[i]);
        uint32_t component_id = get_component_id(it->event_id);
        uint32_t event_id = get_event_id(it->event);

        const ObserverCallbackContext *cb_ctx = it->callback_ctx;
        if (cb_ctx && cb_ctx->callback)
        {
            // invoke the callback
            // printf("Invoking callback %p\n", cb_ctx->callback);
            cb_ctx->callback(entity_id, component_id, event_id, cb_ctx->callback_id);
        }
    }
}

void free_observer_callback_ctx(void *ctx)
{
    ObserverCallbackContext *cb_ctx = ctx;
    if (!cb_ctx)
        return;

    // val_gc(cb_ctx->callback, false); // pin it?  It's a static function, so no?
    free(cb_ctx);
}

// A wrapper function to register an observer
bool register_observer(
    uint32_t *component_ids,
    uint32_t num_components,
    uint32_t *event_ids,
    uint32_t num_events,
    ObserverCallback callback,
    uint32_t callback_id)
{
    printf("Registering observer for %d components\n", num_components);

    if (num_components >= FLECS_TERM_COUNT_MAX)
    {
        printf("Too many terms! Max allowed: %d\n", FLECS_TERM_COUNT_MAX);
        return false;
    }

    ecs_observer_desc_t desc = {0};
    desc.callback = on_observed_component_changed;
    uint32_t i = 0;
    for (i = 0; i < num_events; i++)
    {
        desc.events[i] = get_event_ecs_id(event_ids[i]);
        if (desc.events[i] == 0)
        {
            fprintf(stderr, "Unabled to register observer (event_id %u not found)\n", event_ids[i]);
            return false;
        }
    }
    desc.events[i] = 0; // null terminator required

    for (uint32_t i = 0; i < num_components; i++)
    {
        const ComponentInfo *component_info = get_component_info(component_ids[i]);
        if (component_info == NULL)
        {
            printf("Unabled to register observer (component_id %u not found)\n", component_ids[i]);
            return false;
        }
        desc.query.terms[i].id = component_info->ecs_id;
    }

    ObserverCallbackContext *callback_ctx = malloc(sizeof(ObserverCallbackContext));
    callback_ctx->callback_id = callback_id;
    callback_ctx->callback = callback;
    // val_gc(callback_ctx->callback, true); // pin it?  It's a static function, so no?

    desc.callback_ctx = callback_ctx;
    desc.callback_ctx_free = free_observer_callback_ctx;

    ecs_entity_t observer = ecs_observer_init(world, &desc);

    if (observer == 0)
    {
        fprintf(stderr, "Unable to register observer\n");
        return false;
    }

    return true;
}


EXPORT bool flecs_register_observer(uint32_t *component_ids, uint32_t num_components, uint32_t *event_ids, uint32_t num_events, ObserverCallback callback, uint32_t callback_id)
{
    return register_observer(component_ids, num_components, event_ids, num_events, callback, callback_id);
}
