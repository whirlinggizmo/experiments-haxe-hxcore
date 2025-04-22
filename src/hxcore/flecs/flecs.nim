# lib/flecs/flecs.nim

# header files are in lib/flecs/flecs_wrapper/include
# source files are in lib/flecs/flecs_wrapper/src

{.passC: "-Ilib/flecs/flecs_wrapper/include".}
{.passC: "-I./include".} 
{.passC: "-std=c99".} 
{.passC: "-D_GNU_SOURCE".}

# use the libflecs_wrapper.a
#[
{.passL: "-static".}
{.passL: "-Llib/flecs/flecs_wrapper/lib".}
{.passL: "-lflecs_wrapper".}
{.passL: "-lm".} # order matters, link math after flecs
]#

# include the source directly
{.compile: "flecs_wrapper/src/flecs.c".}
{.compile: "flecs_wrapper/src/flecs_wrapper.c".}
{.compile: "flecs_wrapper/src/flecs_wrapper_world.c".}
{.compile: "flecs_wrapper/src/flecs_wrapper_entity.c".}
{.compile: "flecs_wrapper/src/flecs_wrapper_component.c".}
{.compile: "flecs_wrapper/src/flecs_wrapper_event.c".}
{.compile: "flecs_wrapper/src/systems/move_system.c".}
{.compile: "flecs_wrapper/src/systems/destination_system.c".}


## Event IDs (order matters since these are mapped in the flecs_wrapper.  Note that indecies start at 1, leaving 0 for  unknown event/error)
#    FLECS_HI_COMPONENT_ID + 40, // EcsOnAdd
#    FLECS_HI_COMPONENT_ID + 41, // EcsOnRemove
#    FLECS_HI_COMPONENT_ID + 42, // EcsOnSet
#    FLECS_HI_COMPONENT_ID + 43, // EcsOnDelete
#    FLECS_HI_COMPONENT_ID + 44, // EcsOnDeleteTarget
#    FLECS_HI_COMPONENT_ID + 45, // EcsOnTableCreate
#    FLECS_HI_COMPONENT_ID + 46, // EcsOnTableDelete
##
const
  ecsUnknownEvent*: uint32 = 0
  ecsOnAdd*: uint32 = 1
  ecsOnRemove*: uint32 = 2
  ecsOnSet*: uint32 = 3
  ecsOnDelete*: uint32 = 4
  ecsOnDeleteTarget*: uint32 = 5
  ecsOnTableCreate*: uint32 = 6
  ecsOnTableDelete*: uint32 = 7

proc flecs_component_get_id_by_name*(name: cstring): uint32 {.importc.}
proc flecs_component_is_mark_changed_by_name*(entity_id: uint32, name: cstring): bool {.importc.}
proc flecs_component_is_marked_changed*(entity_id, component_id: uint32): bool {.importc.}
proc flecs_component_is_tag*(component_id: uint32): bool {.importc.}
proc flecs_component_print_registry*() {.importc.}

proc flecs_entity_print_components*(entity_id: uint32) {.importc.}
proc flecs_entity_has_component*(entity_id, component_id: uint32): bool {.importc.}
proc flecs_entity_has_component_by_name*(entity_id: uint32, name: cstring): bool {.importc.}

proc flecs_entity_add_component*(entity_id, component_id: uint32): bool {.importc.}
proc flecs_entity_add_component_by_name*(entity_id: uint32, name: cstring): bool {.importc.}
proc flecs_entity_remove_component*(entity_id, component_id: uint32): bool {.importc.}
proc flecs_entity_remove_component_by_name*(entity_id: uint32, name: cstring): bool {.importc.}

#[
proc flecs_entity_set_velocity*(entity_id: uint32, x, y: float32): bool {.importc.}
proc flecs_entity_get_velocity*(entity_id: uint32, x, y: ptr float32): bool {.importc.}
proc flecs_entity_set_position*(entity_id: uint32, x, y: float32): bool {.importc.}
proc flecs_entity_get_position*(entity_id: uint32, x, y: ptr float32): bool {.importc.}
proc flecs_entity_set_destination*(entity_id: uint32, x, y, speed: float32): bool {.importc.}
proc flecs_entity_get_destination*(entity_id: uint32, x, y, speed: ptr float32): bool {.importc.}

proc flecs_entity_set_component_vec2*(entity_id, component_id: uint32, x, y: float32): bool {.importc.}
proc flecs_entity_get_component_vec2*(entity_id, component_id: uint32, x, y: ptr float32): bool {.importc.}
]#

proc flecs_entity_create*(name: cstring): uint32 {.importc.}
proc flecs_entity_destroy*(entity_id: uint32): bool {.importc.}

type
  FlecsObserverCallback* = proc(entity_id, component_id, event_id : uint32, component_pointer: pointer, component_size: uint32, callback_id: uint32) {.cdecl.}

proc flecs_register_observer*(
  component_ids: ptr uint32,
  num_components: uint32,
  event_ids: ptr uint32,
  num_events: uint32,
  callback: FlecsObserverCallback,
  callback_id: uint32
): bool {.importc.}

#[
type
  TrampolineSystemCallback* = proc(entity_id: uint32, components: ptr pointer, num_components: uint32, callback_id: uint32) {.cdecl.}
proc flecs_register_system*(
  component_ids: ptr uint32,
  num_components: uint32,
  callback: TrampolineSystemCallback,
  callback_id: uint32
): bool {.importc.}
]#

proc flecs_init*() {.importc.}
proc flecs_progress*(delta_time: float32) {.importc.}
proc flecs_fini*() {.importc.}
proc flecs_version*(): cstring {.importc.}

# Observer callback registry, implemented in Nim to help with ease of use
import std/tables
import std/strformat

type
  ObserverCallback = proc(entity, component, event: uint32, component_pointer: pointer, component_size: uint32) {.gcsafe.}
  #SystemCallback = proc(entity: uint32, components: ptr pointer, num_components: uint32, callback_id: uint32) {.gcsafe.}

# Internal state
var
  nextCallbackId {.global.} = 1'u32  # Reserve 0 for invalid ID
  cbMap = initTable[uint32, ObserverCallback]()

# Register a callback and return its ID
proc register_observer_callback(cb: ObserverCallback, id: uint32 = 0'u32): uint32 =
  if cb.isNil:
    echo "⚠️ Warning: tried to register nil callback"
    return 0

  var realId = id
  if realId == 0:
    realId = nextCallbackId
    inc nextCallbackId

  if cbMap.hasKey(realId):
    echo "⚠️ Warning: callback already registered for id ", realId
    return 0

  cbMap[realId] = cb
  return realId

# Called from C — dispatches to registered Nim callbacks
proc flecs_observer_trampoline(entity, component, event: uint32, component_pointer: pointer, component_size: uint32, callback_id: uint32) {.cdecl.} =
  if cbMap.hasKey(callback_id):
    cbMap[callback_id](entity, component, event, component_pointer, component_size)
  else:
    echo "⚠️ No callback registered for id ", callback_id

# Optional utility to unregister
proc flecs_remove_observer_callback*(id: uint32) =
  if cbMap.hasKey(id):
    cbMap.del(id)
    echo "✅ Callback with id ", id, " unregistered."
  else:
    echo "⚠️ Tried to unregister missing callback id ", id

proc flecs_add_observer_callback*(components:openArray[uint32], events:openArray[uint32], callback: ObserverCallback) : uint32 =
  if callback.isNil:
    echo "⚠️ Warning: tried to register nil callback"
    return

  if components.len == 0 or events.len == 0:
    echo "⚠️ Warning: tried to register observer with no components or events"
    return

  let id = register_observer_callback(callback)
  discard flecs_register_observer(
    components[0].addr,
    uint32 components.len,
    events[0].addr,
    uint32 events.len,
    flecs_observer_trampoline,
    id
  )
  return id
