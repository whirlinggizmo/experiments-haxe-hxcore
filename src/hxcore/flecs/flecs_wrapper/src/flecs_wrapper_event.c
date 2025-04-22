// lib/flecs_wrapper/src/flecs_wrapper.c
#define FLECS_OBSERVER

#include <stdlib.h>
#include "flecs.h"
#include "flecs_wrapper.h"
#include "flecs_wrapper_component.h"
#include "flecs_wrapper_entity.h"

#include "flecs_wrapper_world.h" // for world access


// there are fixed number of event types, so we'll just add them directly
#define event_ecs_id_count 8
static ecs_entity_t event_ecs_id_table[8];   /* 0..7 */

void init_event_table(void) {
    event_ecs_id_table[0] = 0;
    event_ecs_id_table[1] = EcsOnAdd;
    event_ecs_id_table[2] = EcsOnRemove;
    event_ecs_id_table[3] = EcsOnSet;
    event_ecs_id_table[4] = EcsOnDelete;
    event_ecs_id_table[5] = EcsOnDeleteTarget;
    event_ecs_id_table[6] = EcsOnTableCreate;
    event_ecs_id_table[7] = EcsOnTableDelete;
    printf("Event table initialized\n");
}

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
// defined in flecs_wrapper_event.h
// typedef void (*ObserverCallback)(uint32_t entity_id, uint32_t component_id, uint32_t event_id, void* component_ptr, uint32_t component_size,uint32_t callback_id);

typedef struct ObserverCallbackContext
{
    ObserverCallback callback;
    uint32_t callback_id;
} ObserverCallbackContext;

// A simple static callback that is registered with flecs observers.
static void on_observed_component_changed(ecs_iter_t *it)
{

    // find out which field/term matches the event component
    int8_t t = -1;
    for (int8_t fi = 0; fi < it->field_count; fi++) {
        if (ecs_field_id(it, fi) == it->event_id) {
            t = fi;
            break;
        }
    }
    if (t == -1) {
        /* Shouldn’t happen, but bail safely */
        return;
    }

    size_t size = ecs_field_size(it, t);          
    void  *column = ecs_field_w_size(it, 0, t);   /* pass 0 = “don’t check” */


    uint32_t component_id = get_component_id(it->event_id);
    uint32_t event_id = get_event_id(it->event);

    //const ComponentInfo *ci = get_component_info(cid);
    //size_t   size = ci->size;
    //void *column = ecs_field_w_size(it, size, 0);   /* term 0 */

    for (int i = 0; i < it->count; i++) {
        uint32_t entity_id   = get_entity_id(it->entities[i]);

        void *comp_i = (char*)column + i * size;

        const ObserverCallbackContext *ctx = it->callback_ctx;
        if (ctx && ctx->callback) {
            //printf("Entity: %u Component: %s Event: %s Size: %zu\n", entity_id, ecs_get_name(world, it->event_id), ecs_get_name(world, it->event), size);
            ctx->callback(entity_id, component_id, event_id, comp_i, (uint32_t)size, ctx->callback_id);
        }
    }
}

static void free_observer_callback_ctx(void *ctx)
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
    //printf("Registering observer for %d components\n", num_components);

    if (num_components >= FLECS_TERM_COUNT_MAX)
    {
        fprintf(stderr, "Too many terms! Max allowed: %d\n", FLECS_TERM_COUNT_MAX);
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
            fprintf(stderr, "Unabled to register observer (component_id %u not found)\n", component_ids[i]);
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
