import ProjectDescription

let project = Project(
    name: "CoreDesignSystem",
    targets: [
        .target(
            name: "CoreDesignSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.tumo.CoreDesignSystem",
            deploymentTargets: .iOS("17.0"),
            sources: ["Sources/**"]
        )
    ]
)
