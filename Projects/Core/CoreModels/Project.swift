import ProjectDescription

let project = Project(
    name: "CoreModels",
    targets: [
        .target(
            name: "CoreModels",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.tumo.CoreModels",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"]
        )
    ]
)
