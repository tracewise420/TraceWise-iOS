// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TraceWiseSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "TraceWiseSDK",
            targets: ["TraceWiseSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "TraceWiseSDK",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk")
            ],
            path: "Sources/TraceWiseSDK"
        ),
        .testTarget(
            name: "TraceWiseSDKTests",
            dependencies: ["TraceWiseSDK"],
            path: "Tests/TraceWiseSDKTests"
        ),
    ]
)