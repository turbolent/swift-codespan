// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-codespan",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "Codespan",
            targets: ["Codespan"]
        ),
        .executable(
            name: "codespan-readme-preview",
            targets: ["CodespanReadmePreview"]
        ),
    ],
    targets: [
        .target(
            name: "Codespan"
        ),
        .executableTarget(
            name: "CodespanReadmePreview",
            dependencies: ["Codespan"]
        ),
        .testTarget(
            name: "CodespanTests",
            dependencies: ["Codespan"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
