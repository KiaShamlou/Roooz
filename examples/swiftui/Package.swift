// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "RoozDemo", platforms: [.macOS(.v12)],
    dependencies: [.package(name: "RoozCalendar", path: "../..")],
    targets: [.executableTarget(name: "RoozDemo", dependencies: [
        .product(name: "RoozCalendar", package: "RoozCalendar")], path: "Sources")])
