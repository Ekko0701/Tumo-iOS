import ProjectDescription

let project = Project(
    name: "StockFeature",
    targets: [
        .target(
            name: "StockFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.tumo.StockFeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "CoreNetwork", path: "../../Core/CoreNetwork"),
                .project(target: "CoreModels", path: "../../Core/CoreModels"),
                .project(target: "CoreDesignSystem", path: "../../Core/CoreDesignSystem")
            ]
        )
    ]
)
