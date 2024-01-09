// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Shu",
    platforms: [.iOS(.v13), .tvOS(.v13), .macOS(.v10_13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "Shu", targets: ["ShuCore"]),
        .library(name: "Shu+CRUD", targets: ["ShuCRUD"]),
        .library(name: "Shu+PromiseKit", targets: ["Shu+PromiseKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.4.0"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ShuCore",
            dependencies: ["Alamofire"],
            path: "Shu/Classes/Core"
        ),
        .target(
            name: "ShuCRUD",
            dependencies: ["ShuCore"],
            path: "Shu/Classes/CRUD"
        ),
        .target(
            name: "Shu+PromiseKit",
            dependencies: ["ShuCore", "PromiseKit"],
            path: "Shu/Classes/Shu+PromiseKit"
        ),
        .testTarget(
            name: "Shu_Tests",
            dependencies: ["ShuCore"]
        )
    ]
)
