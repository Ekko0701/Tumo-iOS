import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .authFeature,
    dependencies: [
        .module(.tumoNetwork),
        .module(.coreStorage),
        .module(.coreModels),
        .module(.coreDesignSystem)
    ]
)
