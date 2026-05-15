import ProjectDescription

public extension Target {
    static func tumoApp(
        dependencies: [TargetDependency]
    ) -> Target {
        .target(
            name: TumoModule.app.name,
            destinations: .iOS,
            product: .app,
            bundleId: Tumo.appBundleId,
            deploymentTargets: Tumo.deploymentTarget,
            infoPlist: .tumoApp,
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: dependencies
        )
    }

    static func tumoFramework(
        module: TumoModule,
        dependencies: [TargetDependency] = []
    ) -> Target {
        .target(
            name: module.name,
            destinations: .iOS,
            product: .framework,
            bundleId: Tumo.bundleId(for: module),
            deploymentTargets: Tumo.deploymentTarget,
            sources: ["Sources/**"],
            dependencies: dependencies
        )
    }

    static func tumoFeatureTests(
        module: TumoModule
    ) -> Target {
        .target(
            name: module.testsName,
            destinations: .iOS,
            product: .unitTests,
            bundleId: Tumo.testsBundleId(for: module),
            deploymentTargets: Tumo.deploymentTarget,
            sources: ["Tests/Sources/**"],
            dependencies: [
                .target(name: module.name)
            ]
        )
    }

    static func tumoFeatureDemo(
        module: TumoModule,
        dependencies: [TargetDependency] = []
    ) -> Target {
        .target(
            name: module.demoName,
            destinations: .iOS,
            product: .app,
            bundleId: Tumo.demoBundleId(for: module),
            deploymentTargets: Tumo.deploymentTarget,
            infoPlist: .tumoDemoApp(module: module),
            sources: ["Demo/Sources/**"],
            dependencies: [
                .target(name: module.name)
            ] + dependencies
        )
    }
}
