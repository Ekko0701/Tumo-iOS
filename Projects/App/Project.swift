import ProjectDescription

let project = Project(
    name: "Tumo",
    targets: [
        .target(
            name: "Tumo",
            destinations: .iOS,
            product: .app,
            bundleId: "com.tumo.ios",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:]
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(target: "CoreNetwork", path: "../Core/CoreNetwork"),
                .project(target: "CoreStorage", path: "../Core/CoreStorage"),
                .project(target: "CoreModels", path: "../Core/CoreModels"),
                .project(target: "CoreDesignSystem", path: "../Core/CoreDesignSystem"),
                .project(target: "AuthFeature", path: "../Features/AuthFeature"),
                .project(target: "StockFeature", path: "../Features/StockFeature"),
                .project(target: "OrderFeature", path: "../Features/OrderFeature"),
                .project(target: "PortfolioFeature", path: "../Features/PortfolioFeature")
            ]
        )
    ]
)

