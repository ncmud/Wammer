// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "libtelnet",
    platforms: [.iOS(.v26)],
    products: [.library(name: "libtelnet", targets: ["libtelnet"])],
    targets: [
        .target(
            name: "libtelnet",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.headerSearchPath("."), .define("HAVE_ZLIB"), .unsafeFlags(["-w"])],
            linkerSettings: [.linkedLibrary("z")]
        )
    ]
)
