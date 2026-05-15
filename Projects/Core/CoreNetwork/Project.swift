import ProjectDescription

let project = Project(
    name: "CoreNetwork",
    targets: [
        .target(
            name: "CoreNetwork",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.tumo.CoreNetwork",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"]
        )
    ]
)
