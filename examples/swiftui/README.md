# SwiftUI booking demo

- macOS: `swift run --package-path examples/swiftui RoozDemo`
- iOS: open `RoozDemo.xcodeproj`, select an iPhone simulator, Run.
- CLI: `xcodebuild -project examples/swiftui/RoozDemo.xcodeproj -scheme RoozDemo -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build`

The local Swift package compiles the C engine into the app. No network package
or binary dependency. The example starts in Farvardin 1403 for reproducible
screenshots; navigate, select a reverse/forward range up to 30 inclusive days,
and clear. Host code owns state, Persian presentation, RTL and validation.
Physical-device signing uses your own development team; no credentials are stored.
