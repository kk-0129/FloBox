// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FloBox",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FloBox",
            targets: ["FloBox"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
          url: "https://github.com/apple/swift-collections.git",
          .upToNextMinor(from:"1.0.0") // or `.upToNextMajor
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FloBox",
            dependencies: [
                .product(name: "Collections", package: "swift-collections")
            ]),
        .testTarget(
            name: "FloBoxTests",
            dependencies: ["FloBox",
                           .product(name: "Collections", package: "swift-collections")
                       ]),
    ]
)
