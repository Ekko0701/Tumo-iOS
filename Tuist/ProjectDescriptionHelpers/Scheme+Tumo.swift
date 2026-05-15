import ProjectDescription

public extension Scheme {
    static func tumoFeature(module: TumoModule) -> Scheme {
        .scheme(
            name: module.name,
            shared: true,
            buildAction: .buildAction(targets: [
                .target(module.name)
            ]),
            testAction: .targets([
                .testableTarget(target: .target(module.testsName))
            ]),
            analyzeAction: .analyzeAction(configuration: .debug)
        )
    }

    static func tumoFeatureDemo(module: TumoModule) -> Scheme {
        .scheme(
            name: module.demoName,
            shared: true,
            buildAction: .buildAction(targets: [
                .target(module.demoName)
            ]),
            runAction: .runAction(
                configuration: .debug,
                executable: .target(module.demoName)
            ),
            archiveAction: .archiveAction(configuration: .release),
            profileAction: .profileAction(
                configuration: .release,
                executable: .target(module.demoName)
            ),
            analyzeAction: .analyzeAction(configuration: .debug)
        )
    }
}
