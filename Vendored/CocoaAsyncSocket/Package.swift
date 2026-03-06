// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "CocoaAsyncSocket",
    platforms: [.iOS(.v26)],
    products: [.library(name: "CocoaAsyncSocket", targets: ["CocoaAsyncSocket"])],
    targets: [
        .target(
            name: "CocoaAsyncSocket",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-w"])],
            linkerSettings: [
                .linkedFramework("Security"),
                .linkedFramework("CFNetwork")
            ]
        )
    ]
)
