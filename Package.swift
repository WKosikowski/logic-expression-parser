// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LeXParser",
    
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LeXParser",
            targets: ["LeXParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LeXParser",
            path: "Sources/lib"
        ),
        .testTarget(
            name: "LeXParserTests",
            dependencies: ["LeXParser"],
            path: "Tests/LeXParserTests"
        ),
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
            .executableTarget(
                name: "lparser",
                dependencies: [
                    .target(name:"LeXParser"),
                    .product(name: "ArgumentParser", package: "swift-argument-parser"),
                ],
                path: "Sources/executable"
            ),
    ]
)



