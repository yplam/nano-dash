// FFI surface for the `voice-engine` Rust cdylib.
//
// This header is the contract of record. The implementations live in the private
// `voice-engine` repo (`crates/voice-engine/src/ffi.rs`), whose compiled library
// hook/build.dart downloads; a symbol missing here is invisible to Dart even
// though the .so exports it. Regenerate the bindings after any change:
//
//   dart run ffigen --config ffigen.yaml

#include <stdint.h>

// Initialize the Dart DL API and store the SendPort native handle for the engine
// event push channel. Call once at startup with the pointer from
// `NativeApi.initializeApiDLData`.
void ve_init(void *api_data, int64_t send_port);

// Load models, open the audio devices and start the engine from a JSON config
// blob. Returns 0 on success; -1 bad config, -2 already open, -3 model/device
// startup failure (an `error` event carries the detail).
int32_t ve_open(const uint8_t *cfg_ptr, uintptr_t cfg_len);

// Queue a sentence (UTF-8) for synthesis + playback. Returns 0 if queued; -1 if
// no engine is open or the text is not valid UTF-8.
int32_t ve_speak(const uint8_t *text_ptr, uintptr_t text_len);

// Begin a reply (an LLM turn): the remote backend opens one connection+session
// for every following ve_speak until ve_speak_end. A no-op for the local backend.
// Returns 0.
int32_t ve_speak_begin(void);

// End the current reply, letting the remote backend finish and close its session.
// A no-op for the local backend. Returns 0.
int32_t ve_speak_end(void);

// Barge-in: discard queued/in-flight TTS and silence playback. Idempotent.
// Returns 0.
int32_t ve_stop(void);

// Wake the engine (run ASR) or put it back to sleep (wake-word only). Non-zero
// `active` wakes, 0 sleeps. A no-op unless wake-gating was enabled at ve_open.
// Returns 0.
int32_t ve_set_active(int32_t active);

// The current lip-sync mouth-opening level in [0, 1], derived from the RMS of the
// TTS audio playing out right now (0.0 when nothing is playing or nothing is
// open). A lock-free read; poll it once per Live2D render frame to drive a
// LipSync parameter.
float ve_speaking_level(void);

// Stop the worker threads and close the audio devices. Idempotent. Returns 0.
int32_t ve_close(void);
