// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "FXForms",
    platforms: [.iOS(.v26)],
    products: [.library(name: "FXForms", targets: ["FXForms"])],
    targets: [
        .target(
            name: "FXForms",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
