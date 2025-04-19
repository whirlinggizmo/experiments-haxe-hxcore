#ifndef TRAMPOLINE_SYSTEM_H
#define TRAMPOLINE_SYSTEM_H

#include "flecs.h"
#include "flecs_wrapper.h"

// typedef void (*TrampolineSystemCallback)(uint32_t entity, void** components, uint32_t num_components);
typedef struct TrampolineSystemContext
{
    SystemCallback callback;
    uint32_t callback_id;
} TrampolineSystemContext;

void TrampolineSystem(ecs_iter_t *it);

#endif // TRAMPOLINE_SYSTEM_H