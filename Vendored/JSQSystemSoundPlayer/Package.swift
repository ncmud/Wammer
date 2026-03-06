// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "JSQSystemSoundPlayer",
    platforms: [.iOS(.v26)],
    products: [.library(name: "JSQSystemSoundPlayer", targets: ["JSQSystemSoundPlayer"])],
    targets: [
        .target(
            name: "JSQSystemSoundPlayer",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
