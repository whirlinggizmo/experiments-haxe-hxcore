// src/hxcore/flecs/flecs_wrapper/src/systems/trampoline_system.c
#include "flecs.h"
#include <stdint.h>

#include "trampoline_system.h"
#include "flecs_wrapper_component.h"
#include "flecs_wrapper_entity.h"

// The trampoline function called by Flecs, allowing us to provide an external update function callback
// It should extract the entities and components and pass them to the callback
void TrampolineSystem(ecs_iter_t *it) {
    printf("System '%s' called for %d entities\n", ecs_get_name(it->world, it->system), it->count);   
    TrampolineSystemContext *cb_ctx = (TrampolineSystemContext*)it->callback_ctx;
    if (!cb_ctx) {
        fprintf(stderr, "Unable to get callback context\n");
        return;
    }

    if (!cb_ctx->callback) {
        fprintf(stderr, "Unable to get callback from callback context\n");
        return;
    }
    
    // Prepare an array to hold component pointers
    void* component_ptrs[FLECS_TERM_COUNT_MAX];
    
    // Get pointers to all components
    // The order is the same as the order of the components in the query
    for (int i = 0; i < it->field_count; i++) {
        ecs_id_t component_ecs_id = ecs_field_id(it, i);
        size_t component_size = get_component_size_by_ecs_id(component_ecs_id);
        component_ptrs[i] = ecs_field_w_size(it, component_size, i);
    }
    
    // Loop through all the entities and pass them and their components to the callback
    for (int i = 0; i < it->count; i++) {
        ecs_entity_t entity_ecs_id = it->entities[i];
        
        // Convert the internal entity_ecs_id to the external entity_id
        uint32_t entity_id = get_entity_id(entity_ecs_id);

        // Call the callback with the entity ID, component pointers, and column count
        //printf("Calling system callback for entity %d\n", entity_id);
        
        // stubbed for debugging
        cb_ctx->callback(entity_id, component_ptrs, (uint32_t)it->field_count, cb_ctx->callback_id);
    }
}