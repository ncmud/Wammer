// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "VTAcknowledgementsViewController",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .visionOS(.v26)],
    products: [.library(name: "VTAcknowledgementsViewController", targets: ["VTAcknowledgementsViewController"])],
    targets: [
        .target(
            name: "VTAcknowledgementsViewController",
            path: "Sources",
            resources: [.process("Resources")],
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-Wmost"])]
        )
    ]
)
