// FFI surface for the `pico-view` Rust cdylib (v2 — frozen at five functions).
//
// Everything except frame delivery travels as protobuf messages; the schemas
// live in the pico-view repo under proto/ (pv_ffi.proto imports pv_wire.proto)
// and the generated Dart types ship in lib/src/gen/. New capabilities are new
// message variants, never new C symbols.

#include <stdint.h>

// Initialize the Dart DL API and store the SendPort native handle for the
// engine event push channel. Call once at startup with the pointer from
// `NativeApi.initializeApiDLData`. Returns 0 on success; -1 when the Dart DL
// API could not be initialized (header/SDK version mismatch) -- fatal: no
// events will ever be delivered.
//
// Events arrive on the SendPort as Uint8List payloads, each one encoded
// `picoview.ffi.PvEvent` message (touch / link transitions / OTA progress).
// Link events are posted on transitions only (the engine reconnects on its
// own; UNAUTHORIZED means the attached device failed hardware attestation).
int32_t pv_init(void *api_data, int64_t send_port);

// Handle one control-plane request: decode `req_len` bytes at `req` as an
// encoded `picoview.ffi.PvRequest`, execute it, and return the encoded
// `PvResponse` via `resp`/`resp_len`. The caller owns the returned buffer and
// MUST release it with pv_free.
//
// Returns 0 whenever a response was produced -- including `error` responses
// (per-request failures travel inside the PvResponse, not as return codes);
// -1 only when no response could be produced (null pointer or undecodable
// request bytes), in which case `resp`/`resp_len` are untouched.
//
// Cheap requests (sys_sample) answer synchronously in the response; long
// operations (open_device, ota_start) answer `ack` and complete via PvEvent
// on the pv_init SendPort.
int32_t pv_request(const uint8_t *req, uintptr_t req_len, uint8_t **resp,
                   uintptr_t *resp_len);

// Free a response buffer returned by pv_request. Null is a no-op. `len` must
// be the exact length pv_request reported for the pointer.
void pv_free(uint8_t *ptr, uintptr_t len);

// Push one RGBA8888 frame (len == width*height*4) to the panel. Fire-and-forget.
// The hot path: deliberately raw (no protobuf) -- a full frame is ~518 KB.
// Returns 0 if enqueued; -1 no device open; -2 enqueue failed.
int32_t pv_lcd_flush(const uint8_t *rgba_ptr, uintptr_t len, uint32_t width,
                     uint32_t height);

// Stop the worker, close the device, and free the host telemetry sampler.
// Idempotent; blocks until the device is fully torn down. Returns 0.
int32_t pv_close(void);
