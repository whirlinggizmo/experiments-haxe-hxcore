// flecs_wrapper_event.h
#ifndef FLECS_WRAPPER_EVENT_H
#define FLECS_WRAPPER_EVENT_H

#include <flecs.h>

#ifdef __cplusplus
extern "C"
{
#endif

    uint32_t get_event_id(const ecs_entity_t ecs_id);
    ecs_entity_t get_event_ecs_id(uint32_t event_id);
    bool register_observer(
        uint32_t *component_ids,
        uint32_t num_components,
        uint32_t *event_ids,
        uint32_t num_events,
        ObserverCallback callback,
        uint32_t callback_id);

#ifdef __cplusplus
}
#endif

#endif // FLECS_WRAPPER_EVENT_H