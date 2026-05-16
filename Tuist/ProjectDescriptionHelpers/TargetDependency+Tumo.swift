import ProjectDescription

public enum TumoExternalDependency: String {
    case composableArchitecture = "ComposableArchitecture"
}

public extension TargetDependency {
    static func module(_ module: TumoModule) -> TargetDependency {
        .project(
            target: module.name,
            path: .relativeToRoot(module.projectPath)
        )
    }

    static func external(_ dependency: TumoExternalDependency) -> TargetDependency {
        .external(name: dependency.rawValue)
    }
}
