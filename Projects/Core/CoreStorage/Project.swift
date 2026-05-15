import ProjectDescription

let project = Project(
    name: "CoreStorage",
    targets: [
        .target(
            name: "CoreStorage",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.tumo.CoreStorage",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"]
        )
    ]
)
