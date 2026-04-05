// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CognitiveEther",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CognitiveEther",
            targets: ["CognitiveEther"]
        ),
    ],
    dependencies: [
        // Add dependencies here, e.g., MLX or llama.cpp bindings
    ],
    targets: [
        .target(
            name: "CognitiveEther",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "CognitiveEtherTests",
            dependencies: ["CognitiveEther"],
            path: "Tests"
        ),
    ]
)
