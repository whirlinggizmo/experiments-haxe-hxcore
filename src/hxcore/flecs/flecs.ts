import { dlopen, ptr } from "bun:ffi";

import { fileURLToPath } from "url";
import { dirname } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const libPath = `${__dirname}/bin/libflecswrapper.so`;
console.log("Loading libflecswrapper from", libPath);

const lib = dlopen(libPath, {
  // Lifecycle
  flecs_init: { args: [], returns: "void" },
  flecs_progress: { args: ["float"], returns: "void" },
  flecs_fini: { args: [], returns: "void" },
  flecs_version: { args: [], returns: "cstring" },

  // Component management
  flecs_component_get_id_by_name: { args: ["cstring"], returns: "int32_t" },
  flecs_component_is_mark_changed_by_name: { args: ["uint32_t", "cstring"], returns: "bool" },
  flecs_component_is_marked_changed: { args: ["uint32_t", "uint32_t"], returns: "bool" },
  flecs_component_is_tag: { args: ["uint32_t"], returns: "bool" },
  flecs_component_print_registry: { args: [], returns: "void" },

  // Entity component inspection
  flecs_entity_print_components: { args: ["uint32_t"], returns: "void" },
  flecs_entity_has_component: { args: ["uint32_t", "uint32_t"], returns: "bool" },
  flecs_entity_has_component_by_name: { args: ["uint32_t", "cstring"], returns: "bool" },

  // Entity component modification
  flecs_entity_add_component: { args: ["uint32_t", "uint32_t"], returns: "bool" },
  flecs_entity_add_component_by_name: { args: ["uint32_t", "cstring"], returns: "bool" },
  flecs_entity_remove_component: { args: ["uint32_t", "uint32_t"], returns: "bool" },
  flecs_entity_remove_component_by_name: { args: ["uint32_t", "cstring"], returns: "bool" },

  // Specific component helpers
  flecs_entity_set_velocity: { args: ["uint32_t", "float", "float"], returns: "bool" },
  flecs_entity_get_velocity: { args: ["uint32_t", "pointer", "pointer"], returns: "bool" },
  flecs_entity_set_position: { args: ["uint32_t", "float", "float"], returns: "bool" },
  flecs_entity_get_position: { args: ["uint32_t", "pointer", "pointer"], returns: "bool" },
  flecs_entity_set_destination: { args: ["uint32_t", "float", "float", "float"], returns: "bool" },
  flecs_entity_get_destination: { args: ["uint32_t", "pointer", "pointer", "pointer"], returns: "bool" },

  // Generic vec2 component helpers
  flecs_entity_set_component_vec2: { args: ["uint32_t", "uint32_t", "float", "float"], returns: "bool" },
  flecs_entity_get_component_vec2: { args: ["uint32_t", "uint32_t", "pointer", "pointer"], returns: "bool" },

  // Entity lifecycle
  flecs_entity_create: { args: ["cstring"], returns: "uint32_t" },
  flecs_entity_destroy: { args: ["uint32_t"], returns: "bool" },

  // Observer registration (callbacks not supported directly in Bun FFI)
  // flecs_register_observer: { ... },
  // System registration (callbacks not supported directly in Bun FFI)
  // flecs_register_system: { ... },
});

console.log("Loaded libflecswrapper");

function stringToPtr(str: string) {
  const buf = Buffer.from(str + "\0", "utf8");
  return ptr(buf);
}

const x_buf = new Float32Array(1);
const y_buf = new Float32Array(1);
const z_buf = new Float32Array(1);

function get_vec2(entity: number, fn: (eid: number, xp: any, yp: any) => boolean) {
  return fn(entity, x_buf, y_buf) ? { x: x_buf[0], y: y_buf[0] } : null;
}

function get_entity_component_vec2_by_name(entity: number, component: string) {
  const id = lib.symbols.flecs_get_component_id_by_name(stringToPtr(component));
  if (!id) return null;

  const success = lib.symbols.flecs_get_entity_component_vec2(entity, id, x_buf, y_buf);
  return success ? { x: x_buf[0], y: y_buf[0] } : null;
}

function set_entity_component_vec2_by_name(
  entity: number,
  component: string,
  x: number,
  y: number
): boolean {
  const id = lib.symbols.flecs_get_component_id_by_name(stringToPtr(component));
  if (!id) return false;
  return lib.symbols.flecs_set_entity_component_vec2(entity, id, x, y);
}

export const flecs = {
  // lifecycle
  init: () => lib.symbols.flecs_init(),
  tick: () => lib.symbols.flecs_progress(),
  destroy: () => lib.symbols.flecs_fini(),

  get_version: () => lib.symbols.flecs_get_version(),

  // entities
  create_entity: (name: string) => lib.symbols.flecs_create_entity(stringToPtr(name)),
  destroy_entity: (entity: number) => lib.symbols.flecs_destroy_entity(entity),

  // component ops
  add_component_by_id: (entity: number, id: number) =>
    lib.symbols.flecs_add_entity_component_by_id(entity, id),
  add_component_by_name: (entity: number, name: string) =>
    lib.symbols.flecs_add_entity_component_by_name(entity, stringToPtr(name)),

  remove_component_by_id: (entity: number, id: number) =>
    lib.symbols.flecs_remove_entity_component_by_id(entity, id),
  remove_component_by_name: (entity: number, name: string) =>
    lib.symbols.flecs_remove_entity_component_by_name(entity, stringToPtr(name)),

  has_component_by_id: (entity: number, id: number) =>
    lib.symbols.flecs_has_entity_component_by_id(entity, id),
  has_component_by_name: (entity: number, name: string) =>
    lib.symbols.flecs_has_entity_component_by_name(entity, stringToPtr(name)),

  get_component_id_by_name: (name: string) =>
    lib.symbols.flecs_get_component_id_by_name(stringToPtr(name)),

  mark_component_changed_by_name: (entity: number, name: string) =>
    lib.symbols.flecs_mark_component_changed_by_name(entity, stringToPtr(name)),
  mark_component_changed_by_id: (entity: number, id: number) =>
    lib.symbols.flecs_mark_component_changed_by_id(entity, id),

  // generic vec2 API
  set_entity_component_vec2_by_name,
  get_entity_component_vec2_by_name,

  // debug helpers
  print_component_registry: () => lib.symbols.flecs_print_component_registry(),
  print_entity_components: (entity: number) =>
    lib.symbols.flecs_print_entity_components(entity),  

  // direct helpers
  set_entity_position: (id: number, x: number, y: number) =>
    lib.symbols.flecs_set_entity_position(id, x, y),
  get_entity_position: (id: number) =>
    get_vec2(id, lib.symbols.flecs_get_entity_position),

  set_entity_velocity: (id: number, x: number, y: number) =>
    lib.symbols.flecs_set_entity_velocity(id, x, y),
  get_entity_velocity: (id: number) =>
    get_vec2(id, lib.symbols.flecs_get_entity_velocity),

  set_entity_destination: (id: number, x: number, y: number, speed: number) =>
    lib.symbols.flecs_set_entity_destination(id, x, y, speed),
  get_entity_destination: (id: number) =>
    lib.symbols.flecs_get_entity_destination(id, x_buf, y_buf, z_buf) ? { x: x_buf[0], y: y_buf[0], speed: z_buf[0] } : null
};
