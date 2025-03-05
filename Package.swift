// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MiniLexer",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "MiniLexer",
            targets: ["MiniLexer"]),
        .library(
            name: "TypeLexing",
            targets: ["TypeLexing"])
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MiniLexer",
            dependencies: []),
        .target(
            name: "TypeLexing",
            dependencies: ["MiniLexer"]),
        .target(
            name: "URLParseSample",
            dependencies: ["MiniLexer", "TypeLexing"]),
        .testTarget(
            name: "MiniLexerTests",
            dependencies: ["MiniLexer"]),
        .testTarget(
            name: "TypeLexingTests",
            dependencies: ["MiniLexer", "TypeLexing"]),
        .testTarget(
            name: "URLParseSampleTests",
            dependencies: ["URLParseSample", "MiniLexer"]),
    ],
    swiftLanguageModes: [.v6]
)
