// nano_live2d — a small C ABI around a headless Live2D Cubism renderer.
//
// One handle owns a background worker thread that holds an offscreen GL context +
// framebuffer and a single model. The worker advances the model on its own
// monotonic clock and renders at a fixed cadence into a triple frame-buffer; the
// host just polls for the latest completed frame. Input (drag/tap/motion/load/
// expression/parameter) is enqueued as commands the worker applies between
// renders; nl_set_lip_sync_value is the one exception, a lock-free store the
// worker samples, because it is meant to be called every frame.
//
// THREADING: every entry point here is thread-safe and may be called from any
// thread. All GL work happens on the handle's own worker thread, so there is no
// "drive from one thread" rule for the caller anymore. nl_create / nl_load block
// until the worker has finished the GL operation and report its result.
//
// FRAME POLLING: nl_acquire_frame returns the newest completed frame (RGBA8888,
// width*height*4, top row first) as a pointer into worker-owned memory, or NULL
// if no new frame has been produced since the last acquire. The pointed-at buffer
// stays valid (the worker will not overwrite it) until the matching
// nl_release_frame. Always pair them: acquire -> consume synchronously -> release.

#ifndef NANO_LIVE2D_H
#define NANO_LIVE2D_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define NL_EXPORT __declspec(dllexport)
#else
#define NL_EXPORT __attribute__((visibility("default")))
#endif

typedef struct nl_ctx* nl_handle;

// Directory holding the framework's Standard shader files (the renderer loads
// shaders from disk). Process-global; set once before nl_load. If never set,
// falls back to the NANO_LIVE2D_SHADER_DIR env var, then a compile-time default.
NL_EXPORT void nl_set_shader_dir(const char* dir);

// Create a handle with an offscreen RGBA framebuffer of the given size. Spawns
// the worker thread and blocks until it has set up GL; returns NULL on failure
// (no GL/EGL, FBO incomplete, ...).
NL_EXPORT nl_handle nl_create(int width, int height);

// Load a model. `dir` is the model directory (with trailing slash), `model3_json`
// the settings filename within it (e.g. "Hiyori.model3.json"). Blocks until the
// worker has loaded it; returns 0 on success, non-zero on failure.
NL_EXPORT int nl_load(nl_handle h, const char* dir, const char* model3_json);

// Look-at target, normalized to [-1, 1] (0,0 = center). Smoothed internally.
// Applied by the worker before its next render.
NL_EXPORT void nl_set_drag(nl_handle h, float nx, float ny);

// Tap at a normalized point [-1, 1]. Hit-tests the model; a body hit starts a
// tap motion. Out-of-body taps are ignored.
NL_EXPORT void nl_tap(nl_handle h, float nx, float ny);

// Number of motions in `group` (the empty string "" selects an unnamed group, as
// many models export). 0 if the model isn't loaded or the group is unknown.
// Blocks for the worker's reply.
NL_EXPORT int nl_motion_count(nl_handle h, const char* group);

// Start motion `index` of `group` at `priority` (0=none, 1=idle, 2=normal,
// 3=force; higher overrides what's playing). `index` < 0 picks a random one.
// Fire-and-forget: the worker starts it before its next render.
NL_EXPORT void nl_start_motion(nl_handle h, const char* group, int index,
                               int priority);

// Mouth openness in [0, 1] (values outside are clamped), applied to the model's
// LipSync parameters. Drive it from the amplitude of whatever audio is playing —
// a speech RMS, scaled to taste — and keep calling it; the worker eases toward
// the value with a short attack and a slower release, so a per-audio-frame or
// per-render-frame call rate both look right. Unlike everything else here this
// bypasses the command queue (a lock-free store), so it is cheap enough to call
// every frame. No-op for models whose model3.json declares no LipSync group.
NL_EXPORT void nl_set_lip_sync_value(nl_handle h, float value);

// Number of expressions the loaded model declares, or 0 if none/not loaded.
NL_EXPORT int nl_expression_count(nl_handle h);

// Copy the name of expression `index` into `buf` (NUL-terminated, truncated to
// fit). Returns the name's length excluding the NUL — which may exceed
// `buf_len - 1`, meaning the name was truncated — or 0 if `index` is out of
// range. Reads a cache filled at load time; does not touch the worker.
NL_EXPORT int nl_expression_name(nl_handle h, int index, char* buf, int buf_len);

// Fade to the expression named `name` (one of nl_expression_name's), or back to
// no expression when `name` is NULL or empty. Unknown names are ignored.
NL_EXPORT void nl_set_expression(nl_handle h, const char* name);

// Pin parameter `id` (a Cubism parameter id, e.g. "ParamMouthForm") to `value`,
// blended by `weight` in [0, 1]. The override is re-applied after motions and
// effects on every frame until nl_clear_parameter, so it always wins. Ignored if
// the model has no such parameter. Allocates on the command queue — fine per
// gesture, too heavy per frame; use nl_set_lip_sync_value for the mouth.
NL_EXPORT void nl_set_parameter(nl_handle h, const char* id, float value,
                                float weight);

// As nl_set_parameter, but adds to whatever the motions and effects produced
// rather than replacing it.
NL_EXPORT void nl_add_parameter(nl_handle h, const char* id, float value,
                                float weight);

// Drop the override on `id`, or on every parameter when `id` is NULL or empty.
NL_EXPORT void nl_clear_parameter(nl_handle h, const char* id);

// Current value of parameter `id` as of the worker's last update (after motions,
// effects and overrides). 0 if the model isn't loaded or has no such parameter.
// Blocks for the worker's reply.
NL_EXPORT float nl_get_parameter(nl_handle h, const char* id);

// Acquire the newest completed frame: RGBA8888 (width*height*4), top row first.
// Returns NULL if no new frame has been produced since the last acquire. The
// buffer is owned by the worker and stays valid until nl_release_frame; copy or
// consume it synchronously, then release. Always pair with nl_release_frame.
NL_EXPORT const uint8_t* nl_acquire_frame(nl_handle h);

// Release the frame returned by the last nl_acquire_frame, letting the worker
// reuse that buffer. No-op if nothing is currently acquired.
NL_EXPORT void nl_release_frame(nl_handle h);

// Pause or resume the worker's render loop. When inactive the worker blocks
// (no rendering, no animation advance) until reactivated or a command arrives,
// dropping its CPU/GPU use to ~0 — use this while the model is off-screen. A
// fresh handle starts active. On resume the animation continues from where it
// froze (no dt catch-up). Cheap to toggle; safe to call repeatedly.
NL_EXPORT void nl_set_active(nl_handle h, int active);

// Pixel dimensions the handle was created with.
NL_EXPORT int nl_width(nl_handle h);
NL_EXPORT int nl_height(nl_handle h);

// Stop the worker thread (joining it) and release all GL resources.
NL_EXPORT void nl_destroy(nl_handle h);

#ifdef __cplusplus
}
#endif

#endif  // NANO_LIVE2D_H
