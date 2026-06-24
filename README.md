# NanoDash

NanoDash is a Flutter desktop app (Linux/macOS/Windows) that mirrors a Flutter
widget subtree to an external **SPI LCD** driven over a **CH347 USB bridge**, and
feeds physical capacitive-touch events from the panel back into that same subtree.

The display/touch engine is Rust; Flutter talks to it through FFI.