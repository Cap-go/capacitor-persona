// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapgoCapacitorIntune",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "CapgoCapacitorIntune",
            targets: ["IntunePlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/microsoftconnect/ms-intune-app-sdk-ios.git", exact: "21.5.1"),
        .package(url: "https://github.com/AzureAD/microsoft-authentication-library-for-objc.git", exact: "2.9.0")
    ],
    targets: [
        .target(
            name: "IntunePlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "IntuneMAMSwift", package: "ms-intune-app-sdk-ios"),
                .product(name: "MSAL", package: "microsoft-authentication-library-for-objc")
            ],
            path: "ios/Sources/IntunePlugin"),
        .testTarget(
            name: "IntunePluginTests",
            dependencies: ["IntunePlugin"],
            path: "ios/Tests/IntunePluginTests")
    ]
)
