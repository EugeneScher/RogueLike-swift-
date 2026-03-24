// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RogueLike",
    products: [
        .executable(
            name: "RogueLike",
            targets: ["RogueLike"]
        )
    ],
    targets: [
        .target(
            name: "CCurses",
            dependencies: [],
            path: "CCurses"
        ),
        .executableTarget(
            name: "RogueLike",
            dependencies: ["CCurses"],
            path: "Sources/RogueLike",
            linkerSettings: [
                .linkedLibrary("ncurses")
            ]
        )
    ]
)
