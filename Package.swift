// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapgoCapacitorPersona",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapgoCapacitorPersona",
            targets: ["PersonaPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/persona-id/inquiry-ios-2.git", exact: "2.41.2")
    ],
    targets: [
        .target(
            name: "PersonaPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "PersonaInquirySDK2", package: "inquiry-ios-2")
            ],
            path: "ios/Sources/PersonaPlugin"),
        .testTarget(
            name: "PersonaPluginTests",
            dependencies: ["PersonaPlugin"],
            path: "ios/Tests/PersonaPluginTests")
    ]
)
