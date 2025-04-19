#ifndef FLECS_WRAPPER_SYSTEM_H
#define FLECS_WRAPPER_SYSTEM_H


#include "flecs.h"
#include "flecs_wrapper.h"

#ifdef __cplusplus
extern "C"
{
#endif


// Define a generic system callback type
//typedef void (*TrampolineSystemCallback)(uint32_t entity, void** components, uint32_t num_components);

/*
// Registration function
ecs_entity_t register_system(
    uint32_t* components,
    uint32_t num_components,
    SystemCallback callback,
    uint32_t callback_id
);
*/

#ifdef __cplusplus
}
#endif

#endif // FLECS_WRAPPER_SYSTEM_H