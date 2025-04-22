// lib/flecs_wrapper/src/flecs_wrapper_system.c

#include <stdlib.h>

#include "flecs.h"
#include "flecs_wrapper.h"

#include "flecs_wrapper_component.h"

#include "systems/trampoline_system.h"

#include "flecs_wrapper_world.h" // for world access


static void free_trampoline_system_ctx(void *ctx)
{
    TrampolineSystemContext *cb_ctx = ctx;
    if (!cb_ctx)
        return;

    // val_gc(cb_ctx->callback, false); // pin it?  It's a static function, so no?
    free(cb_ctx);
}

// Registration function
static ecs_entity_t register_system(
    const char* name,
    uint32_t* components,
    uint32_t num_components,
    SystemCallback callback,
    uint32_t callback_id
) {


    // from flecs.h
    /** Shorthand for creating a system with ecs_system_init().
 *
 * Example:
 *
 * @code
 * ecs_system(world, {
 *   .entity = ecs_entity(world, {
 *     .name = "MyEntity",
 *     .add = ecs_ids( ecs_dependson(EcsOnUpdate) )
 *   }),
 *   .query.terms = {
 *     { ecs_id(Position) },
 *     { ecs_id(Velocity) }
 *   },
 *   .callback = Move
 * });
 * @endcode
 */
 // #define ecs_system(world, ...)\
 //     ecs_system_init(world, &(ecs_system_desc_t) __VA_ARGS__ )

    /*
    ecs_system_desc_t desc = {
        .entity = ecs_entity(world, {
            .name = "TrampolineSystem",
            .add = ecs_ids( ecs_dependson(EcsOnUpdate) )
        }),
        .callback = TrampolineSystem,
        .query.terms = {
            { ecs_id(Position) },
            { ecs_id(Velocity) }
        },
    };
    ecs_system_init(world, &desc);
    */

    // The ecs_system_desc_t is used to describe the system to be created
    // The ecs_term_t is used to describe the components that the system will process
    // flecs has preallocated arrays for them, so we need to fill them out (and ensure there is a null terminator)

    ecs_system_desc_t desc = {0};
    desc.callback = TrampolineSystem;
    desc.entity = ecs_entity(world, {
        .name = name, // TODO: do we need to strdup?
        .add = ecs_ids( ecs_dependson(EcsOnUpdate) )
    });
    
    if (num_components > FLECS_TERM_COUNT_MAX) {
        fprintf(stderr, "Too many components! Max allowed: %d\n", 32);
        return 0;
    }

    for (uint32_t i = 0; i < num_components; i++)
    {
        const ComponentInfo *component_info = get_component_info(components[i]);
        if (component_info == NULL)
        {
            printf("Unabled to register system (component_id %u not found)\n", components[i]);
            return 0;
        }
        desc.query.terms[i].id = component_info->ecs_id;
        desc.query.terms[i].oper = EcsAnd; // TODO: this should be a parameter
    }
    // null terminator required
    desc.query.terms[num_components] = (ecs_term_t){0};


    TrampolineSystemContext *callback_ctx = malloc(sizeof(TrampolineSystemContext));
    callback_ctx->callback = callback;
    callback_ctx->callback_id = callback_id;

    desc.callback_ctx = callback_ctx;
    desc.callback_ctx_free = free_trampoline_system_ctx;

    ecs_entity_t system = ecs_system_init(world, &desc);
    return system;
}

EXPORT bool flecs_register_system(const char* name, uint32_t* components, uint32_t num_components, SystemCallback callback, uint32_t callback_id) {
    ecs_entity_t result = register_system( name, components, num_components, callback, callback_id);
    printf("Registered system '%s' with id: %ld\n", name, result);
    return result != 0;
}