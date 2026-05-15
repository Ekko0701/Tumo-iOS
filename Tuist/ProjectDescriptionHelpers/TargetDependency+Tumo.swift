import ProjectDescription

public extension TargetDependency {
    static func module(_ module: TumoModule) -> TargetDependency {
        .project(
            target: module.name,
            path: .relativeToRoot(module.projectPath)
        )
    }
}
