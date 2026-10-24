// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "RoozCalendar",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)],
    products: [.library(name: "RoozCalendar", targets: ["RoozCalendar"])],
    targets: [
        .target(name: "CRooz", path: "core", publicHeadersPath: "include"),
        .target(name: "RoozCalendar", dependencies: ["CRooz"], path: "bindings/swift/Sources"),
        .testTarget(name: "RoozCalendarTests", dependencies: ["RoozCalendar"], path: "bindings/swift/Tests")
    ]
)
