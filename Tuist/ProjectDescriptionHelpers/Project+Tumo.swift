import ProjectDescription

public extension Project {
    static func tumoApp(
        dependencies: [TargetDependency]
    ) -> Project {
        Project(
            name: TumoModule.app.name,
            settings: .tumoDefault,
            targets: [
                .tumoApp(dependencies: dependencies)
            ]
        )
    }

    static func tumoFramework(
        module: TumoModule,
        dependencies: [TargetDependency] = []
    ) -> Project {
        Project(
            name: module.name,
            settings: .tumoDefault,
            targets: [
                .tumoFramework(
                    module: module,
                    dependencies: dependencies
                )
            ]
        )
    }

    static func tumoFeature(
        module: TumoModule,
        dependencies: [TargetDependency] = []
    ) -> Project {
        Project(
            name: module.name,
            settings: .tumoDefault,
            targets: [
                .tumoFramework(
                    module: module,
                    dependencies: dependencies
                ),
                .tumoFeatureTests(module: module),
                .tumoFeatureDemo(
                    module: module,
                    dependencies: dependencies
                )
            ]
        )
    }
}
