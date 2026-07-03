// FFI surface for the `pico-view` Rust cdylib.

#include <stdint.h>

// Initialize the Dart DL API and store the SendPort native handle for the touch
// event push channel. Call once at startup with the pointer from
// `NativeApi.initializeApiDLData`.
void pv_init(void *api_data, int64_t send_port);

// Open the panel device and start the worker from a JSON config blob.
// Returns 0 on success; -1 bad config, -2 already open, -3 device/setup failure,
// -4 unauthorized device (hardware attestation failed or unsupported -- the
// device is not, provably, genuine pico-view hardware).
int32_t pv_open(const uint8_t *cfg_ptr, uintptr_t cfg_len);

// Push one RGBA8888 frame (len == width*height*4) to the panel. Fire-and-forget.
// Returns 0 if enqueued; -1 no device open; -2 enqueue failed.
int32_t pv_lcd_flush(const uint8_t *rgba_ptr, uintptr_t len, uint32_t width,
                     uint32_t height);

// Stream a signed firmware image to the device and commit it. Fire-and-forget:
// progress/result arrive as `"type":"ota"` JSON events on the pv_init SendPort.
// Returns 0 if enqueued; -1 no device open / null pointer; -2 enqueue failed.
int32_t pv_ota_start(const uint8_t *img_ptr, uintptr_t len);

// Ask the device to reboot into its factory recovery image.
// Returns 0 if enqueued; -1 no device open; -2 enqueue failed.
int32_t pv_enter_recovery(void);

// Stop the worker and close the device. Idempotent. Returns 0.
int32_t pv_close(void);

// --- Host system telemetry ---------------------------------------------------
// Sample the HOST machine (CPU/RAM/network/temperatures) for the dashboard's
// system-monitor module. Independent of any open device; pull model.

// Start the host system sampler. Idempotent. Returns 0.
int32_t pv_sys_open(void);

// Sample host telemetry once. Returns a newly-allocated, NUL-terminated UTF-8
// JSON string that the caller MUST free with pv_sys_free, or null on failure.
// Opens the sampler on first use.
char *pv_sys_sample(void);

// Free a string returned by pv_sys_sample. Null is a no-op.
void pv_sys_free(char *ptr);

// Stop the host sampler and free its state. Idempotent. Returns 0.
int32_t pv_sys_close(void);
