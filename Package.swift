// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Switor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Switor", targets: ["Switor"])
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "Switor",
            dependencies: ["HotKey"],
            path: "Switor",
            exclude: ["Info.plist", "Switor.entitlements"]
        )
    ]
)
