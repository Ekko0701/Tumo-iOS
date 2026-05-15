import ProjectDescription

let project = Project(
    name: "AuthFeature",
    targets: [
        .target(
            name: "AuthFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.tumo.AuthFeature",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "CoreNetwork", path: "../../Core/CoreNetwork"),
                .project(target: "CoreStorage", path: "../../Core/CoreStorage"),
                .project(target: "CoreModels", path: "../../Core/CoreModels"),
                .project(target: "CoreDesignSystem", path: "../../Core/CoreDesignSystem")
            ]
        )
    ]
)
