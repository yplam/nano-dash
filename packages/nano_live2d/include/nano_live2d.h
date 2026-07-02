// nano_live2d — a small C ABI around a headless Live2D Cubism renderer.

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

typedef struct nl_ctx *nl_handle;

// Directory holding the framework's Standard shader files (the renderer loads
// shaders from disk).
NL_EXPORT void nl_set_shader_dir(const char *dir);

// Create a handle with an offscreen RGBA framebuffer of the given size. Spawns
// the worker thread and blocks until it has set up GL; returns NULL on failure.
NL_EXPORT nl_handle nl_create(int width, int height);

// Load a model. `dir` is the model directory (with trailing slash), `model3_json`
// the settings filename within it. returns 0 on success, non-zero on failure.
NL_EXPORT int nl_load(nl_handle h, const char *dir, const char *model3_json);

// Look-at target, normalized to [-1, 1] (0,0 = center). Smoothed internally.
// Applied by the worker before its next render.
NL_EXPORT void nl_set_drag(nl_handle h, float nx, float ny);

// Tap at a normalized point [-1, 1]. Hit-tests the model; a body hit starts a
// tap motion. Out-of-body taps are ignored.
NL_EXPORT void nl_tap(nl_handle h, float nx, float ny);

// Number of motions in `group`. 0 if the model isn't loaded or the group is unknown.
NL_EXPORT int nl_motion_count(nl_handle h, const char *group);

// Start motion `index` of `group` at `priority` (0=none, 1=idle, 2=normal,
// 3=force; higher overrides what's playing). `index` < 0 picks a random one.
NL_EXPORT void nl_start_motion(nl_handle h, const char *group, int index,
                               int priority);

// Acquire the newest completed frame: RGBA8888 (width*height*4), top row first.
// Returns NULL if no new frame has been produced since the last acquire. The
// buffer is owned by the worker and stays valid until nl_release_frame; copy or
// consume it synchronously, then release. Always pair with nl_release_frame.
NL_EXPORT const uint8_t *nl_acquire_frame(nl_handle h);

// Release the frame returned by the last nl_acquire_frame, letting the worker
// reuse that buffer.
NL_EXPORT void nl_release_frame(nl_handle h);

// Pixel dimensions the handle was created with.
NL_EXPORT int nl_width(nl_handle h);

NL_EXPORT int nl_height(nl_handle h);

// Stop the worker thread (joining it) and release all GL resources.
NL_EXPORT void nl_destroy(nl_handle h);

#ifdef __cplusplus
}
#endif

#endif  // NANO_LIVE2D_H
