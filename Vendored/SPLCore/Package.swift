// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "SPLCore",
    platforms: [.iOS(.v26)],
    products: [.library(name: "SPLCore", targets: ["SPLCore"])],
    dependencies: [
        .package(name: "MagicalRecord", path: "../MagicalRecord"),
        .package(name: "libextobjc", path: "../libextobjc"),
    ],
    targets: [
        .target(
            name: "SPLCore",
            dependencies: ["MagicalRecord", "libextobjc"],
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-w"])]
        )
    ]
)
