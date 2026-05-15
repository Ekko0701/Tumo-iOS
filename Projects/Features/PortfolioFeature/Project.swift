import ProjectDescription

let project = Project(
    name: "PortfolioFeature",
    targets: [
        .target(
            name: "PortfolioFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.tumo.PortfolioFeature",
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
