import ProjectDescription

let project = Project(
    name: "OrderFeature",
    targets: [
        .target(
            name: "OrderFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.tumo.OrderFeature",
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
