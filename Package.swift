// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "DiffStudy",
    products: [
        .executable(
            name: "DiffStudy",
            targets: ["DiffStudy"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "DiffStudy",
            dependencies: []),
        .testTarget(
            name: "DiffStudyTests",
            dependencies: ["DiffStudy"]),
    ]
)
