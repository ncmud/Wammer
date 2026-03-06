// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "OCMock",
    platforms: [.iOS(.v26)],
    products: [.library(name: "OCMock", targets: ["OCMock"])],
    targets: [
        .target(
            name: "OCMock",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags(["-fno-objc-arc"])
            ]
        )
    ]
)
