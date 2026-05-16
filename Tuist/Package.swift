// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "ComposableArchitecture": .framework
    ]
)
#endif

let package = Package(
    name: "Tumo",
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.25.5"
        )
    ]
)
