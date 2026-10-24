# Rooz Dart binding

Dependency-free native FFI wrapper. See the repository root README for examples,
accuracy definitions and native library packaging instructions. Supported runtime
targets are native Dart/Flutter; this package is not browser-compatible.

The binding allocates with `rc_alloc` and frees with `rc_free`, including error
paths. CivilDate is immutable, numeric FFI inputs are range-checked, and selection
is an immutable reducer. `validator` can reject a proposed interval atomically.
