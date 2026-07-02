// FFI bindings to the `libnano_live2d` C ABI (see `include/nano_live2d.h`).
//
// These `@Native` externs resolve to the code asset emitted by `hook/build.dart`
// (whose name matches this library's URI), so the bundled library is found
// automatically with no DynamicLibrary.open / `$NANO_LIVE2D_LIB`.
library;

// Names mirror the C ABI symbols.
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

@ffi.Native<ffi.Void Function(ffi.Pointer<Utf8>)>()
external void nl_set_shader_dir(ffi.Pointer<Utf8> dir);

@ffi.Native<ffi.Pointer<ffi.Void> Function(ffi.Int32, ffi.Int32)>()
external ffi.Pointer<ffi.Void> nl_create(int width, int height);

@ffi.Native<
    ffi.Int32 Function(
        ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>)>()
external int nl_load(
    ffi.Pointer<ffi.Void> h, ffi.Pointer<Utf8> dir, ffi.Pointer<Utf8> model3Json);

// Input commands are enqueued for the worker thread (a mutex + condvar), so they
// are not leaf calls.
@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Float, ffi.Float)>()
external void nl_set_drag(ffi.Pointer<ffi.Void> h, double nx, double ny);

@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>, ffi.Float, ffi.Float)>()
external void nl_tap(ffi.Pointer<ffi.Void> h, double nx, double ny);

@ffi.Native<ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>)>()
external int nl_motion_count(ffi.Pointer<ffi.Void> h, ffi.Pointer<Utf8> group);

@ffi.Native<
    ffi.Void Function(
        ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>, ffi.Int32, ffi.Int32)>()
external void nl_start_motion(
    ffi.Pointer<ffi.Void> h, ffi.Pointer<Utf8> group, int index, int priority);

// Acquire/release the newest worker-rendered frame. acquire returns nullptr when
// no new frame is available; both touch the frame mutex, so neither is leaf.
@ffi.Native<ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Void>)>()
external ffi.Pointer<ffi.Uint8> nl_acquire_frame(ffi.Pointer<ffi.Void> h);

@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>)>()
external void nl_release_frame(ffi.Pointer<ffi.Void> h);

@ffi.Native<ffi.Int32 Function(ffi.Pointer<ffi.Void>)>(isLeaf: true)
external int nl_width(ffi.Pointer<ffi.Void> h);

@ffi.Native<ffi.Int32 Function(ffi.Pointer<ffi.Void>)>(isLeaf: true)
external int nl_height(ffi.Pointer<ffi.Void> h);

@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Void>)>()
external void nl_destroy(ffi.Pointer<ffi.Void> h);
