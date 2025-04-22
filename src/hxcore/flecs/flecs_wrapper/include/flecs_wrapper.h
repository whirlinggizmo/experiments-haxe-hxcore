// flecs_wrapper.h
#ifndef FLECS_WRAPPER_H
#define FLECS_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#define EXPORT __attribute__((visibility("default")))

#ifdef __cplusplus
extern "C"
{
#endif
   
    // Component management
    int32_t flecs_component_get_id_by_name(const char *name);
    bool flecs_component_is_mark_changed_by_name(uint32_t entity_id, const char *component_name);
    bool flecs_component_is_marked_changed(uint32_t entity_id, uint32_t component_id);
    bool flecs_component_is_tag(uint32_t component_id);
    void flecs_component_print_registry(void);

    // Entity component inspection
    void flecs_entity_print_components(uint32_t entity_id);
    bool flecs_entity_has_component(uint32_t entity_id, uint32_t component_id);
    bool flecs_entity_has_component_by_name(uint32_t entity_id, const char *component_name);

    // Entity component modification
    bool flecs_entity_add_component(uint32_t entity_id, uint32_t component_id);
    bool flecs_entity_add_component_by_name(uint32_t entity_id, const char *component_name);
    bool flecs_entity_remove_component(uint32_t entity_id, uint32_t component_id);
    bool flecs_entity_remove_component_by_name(uint32_t entity_id, const char *component_name);
    bool flecs_entity_set_component_data(uint32_t entity_id, uint32_t component_id, const void *component_data_ptr);
    const void* flecs_entity_get_component_data(uint32_t entity_id, uint32_t component_id);

    // Specific component helpers
    /*
    bool flecs_entity_set_velocity(uint32_t entity_id, float x, float y);
    bool flecs_entity_get_velocity(uint32_t entity_id, float *x, float *y);
    bool flecs_entity_set_position(uint32_t entity_id, float x, float y);
    bool flecs_entity_get_position(uint32_t entity_id, float *x, float *y);
    bool flecs_entity_set_destination(uint32_t entity_id, float x, float y, float speed);
    bool flecs_entity_get_destination(uint32_t entity_id, float *x, float *y, float *speed);

    // Generic vector2 component helpers
    bool flecs_entity_set_component_vec2(uint32_t entity_id, uint32_t component_id, float x, float y);
    bool flecs_entity_get_component_vec2(uint32_t entity_id, uint32_t component_id, float *x, float *y);
    */

    // Entity lifecycle
    uint32_t flecs_entity_create(const char *name);
    bool flecs_entity_destroy(uint32_t entity_id);

    // Observer registration
    typedef void (*ObserverCallback)(uint32_t entity_id, uint32_t component_id, uint32_t event_id, void* component_ptr, uint32_t component_size,uint32_t callback_id);
    bool flecs_register_observer(uint32_t *component_ids, uint32_t num_components, uint32_t *event_ids, uint32_t num_events, ObserverCallback callback, uint32_t callback_id);

    // System registration
    typedef void (*SystemCallback)(uint32_t entity_id, void** components, uint32_t num_components, uint32_t callback_id);
    bool flecs_register_system(const char* name, uint32_t *component_ids, uint32_t num_components, SystemCallback callback, uint32_t callback_id);

    // Lifecycle management
    void flecs_init(void);
    void flecs_progress(float delta_time);
    void flecs_fini(void);

    // Version
    const char *flecs_version(void);

#ifdef __cplusplus
}
#endif

#endif // FLECS_WRAPPER_H