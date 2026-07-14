// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DownloadRecycler",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DownloadRecycler", targets: ["DownloadRecycler"]),
    ],
    dependencies: [
        .package(path: "../StatusItemKit"),
    ],
    targets: [
        .executableTarget(
            name: "DownloadRecycler",
            dependencies: [.product(name: "StatusItemKit", package: "StatusItemKit")]
        ),
    ]
)
