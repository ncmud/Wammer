// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "MyLilTimer",
    platforms: [.iOS(.v26)],
    products: [.library(name: "MyLilTimer", targets: ["MyLilTimer"])],
    targets: [
        .target(
            name: "MyLilTimer",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
