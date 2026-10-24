# Kotlin / Android Compose booking demo

JDK 17, Android SDK 35, Gradle 8.10.2. From the repository root:

```sh
./gradlew -p examples/compose :app:assembleDebug :app:assembleAndroidTest
./gradlew -p examples/compose :app:installDebug
# With a booted Android emulator/device:
./gradlew -p examples/compose :app:connectedDebugAndroidTest
```

Open this directory in Android Studio. `:rooz` is the local Android library;
its NDK build bundles JNI for arm64-v8a, armeabi-v7a and x86_64. No hand-copied
native binaries. The app demonstrates RTL, Persian digits, customizable cells,
month navigation, reverse ranges, 30-day limit, rejection feedback and reset.
The Compose instrumentation test exercises the actual packaged JNI, not a mock.
