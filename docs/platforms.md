# Build and integration matrix

| Consumer | Integration | Local verification in this delivery |
|---|---|---|
| C/C++ on macOS | Make or CMake | Compiled and executed, including sanitizers |
| Swift / SwiftUI | Root Swift Package | Unit tests and SwiftUI library compiled on macOS |
| Kotlin/JVM | JNI + Kotlin source | Compiled and executed on macOS/JDK 17 |
| Android / Kotlin | Gradle library + NDK CMake | Build definition and CI job; device/AAR validation pending |
| Dart native | Dynamic library + `dart:ffi` | Analyzer and real FFI smoke tests passed on macOS |
| Flutter native | Dart binding + builder view | 5 library + 2 app widget tests passed with the real C library |
| Windows / Linux C | CMake | CI jobs supplied; local cross-OS runtime not exercised |
| iOS | Swift Package or statically linked C for Dart | iOS simulator app compiled; interactive/physical-device validation pending |
| Browser/web | — | Not supported by this native FFI release; WASM is a separate milestone |

CI configuration is not evidence of a completed CI run. All language APIs share
the C algorithms, but each shipping artifact still needs its platform build tests.

## Native build

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
cmake --install build --prefix ./dist
```

Outputs: `librooz.dylib` (macOS), `librooz.so` (Linux), or `rooz.dll` (Windows).
Use `-DBUILD_SHARED_LIBS=OFF` for a static library. MSVC builds use UTF-8 source.
For Android use the NDK toolchain, not the host compiler.

## Swift

Add this repository root as a local Swift Package dependency. Import `RoozCalendar`.
The package compiles the shared C sources into the app; no downloaded binaries.
`examples/swiftui/Sources/BookingCalendar.swift` demonstrates a controlled RTL range picker.

```sh
swift test
```

## Android / Kotlin

With JDK 17, Gradle 8.10.2, Android SDK 35, NDK and CMake 3.22.1 installed:

```sh
./gradlew -p bindings/kotlin assembleRelease
```

Consume the resulting AAR from `bindings/kotlin/build/outputs/aar/`.
The library builds arm64-v8a, armeabi-v7a and x86_64 JNI libraries. Consumer R8
rules preserve native method names. `examples/compose` is a runnable Compose/Material3 app using the local library.

For desktop JVM, compile the JNI CMake target in `bindings/kotlin/jni`, compile
the Kotlin source into your JAR and include the JNI library on `java.library.path`.

```sh
JAVA_HOME=/path/to/jdk KOTLINC=/path/to/kotlinc tools/test_kotlin.sh
```

## Dart and Flutter

Use a local path dependency on `bindings/dart`. Build a library for the target ABI
and load its actual path through `Rooz.open(path)`. For Flutter UI, depend on
`bindings/flutter`; it references the Dart binding by relative path in this repo.
The monorepo `bindings/flutter_native` FFI plugin builds and bundles C for the target.
Registry publication is separate; packages with local dependencies use `publish_to: none`.
The manual routes below apply to raw Dart or custom native hosts.

- Android: package a separately built `librooz.so` under each ABI's `jniLibs`.
- macOS/Linux/Windows: bundle the native library with the app and resolve its path.
- iOS: statically link Rooz and use `Rooz(DynamicLibrary.process())`; retain `rc_*`
  symbols using the linker's force-load option so dead stripping does not remove them.
- Never copy the host macOS library into an Android/iOS/Windows application.

```sh
make all
dart analyze bindings/dart
dart run bindings/dart/test/smoke.dart /absolute/path/to/librooz.dylib
cd bindings/flutter
flutter pub get
ROOZ_LIBRARY=/absolute/path/to/librooz.dylib flutter test
```

For another programming language, bind the documented C ABI. There are no shipped
C#, JavaScript, Python or Rust packages yet; generic FFI compatibility is not a
claim of tested language bindings.
