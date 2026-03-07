// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "SSAccessibility",
    platforms: [.iOS(.v26)],
    products: [.library(name: "SSAccessibility", targets: ["SSAccessibility"])],
    targets: [
        .target(
            name: "SSAccessibility",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-Wmost"])]
        )
    ]
)
