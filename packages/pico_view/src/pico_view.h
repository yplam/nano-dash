// FFI surface for the `pico-view` Rust cdylib.

#include <stdint.h>

// Initialize the Dart DL API and store the SendPort native handle for the touch
// event push channel. Call once at startup with the pointer from
// `NativeApi.initializeApiDLData`.
void pv_init(void *api_data, int64_t send_port);

// Open the CH347 device and start the worker from a JSON config blob.
// Returns 0 on success; -1 bad config, -2 already open, -3 device/setup failure.
int32_t pv_open(const uint8_t *cfg_ptr, uintptr_t cfg_len);

// Push one RGBA8888 frame (len == width*height*4) to the panel. Fire-and-forget.
// Returns 0 if enqueued; -1 no device open; -2 enqueue failed.
int32_t pv_lcd_flush(const uint8_t *rgba_ptr, uintptr_t len, uint32_t width,
                     uint32_t height);

// Stop the worker and close the device. Idempotent. Returns 0.
int32_t pv_close(void);
