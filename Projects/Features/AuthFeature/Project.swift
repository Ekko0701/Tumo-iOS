import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .authFeature,
    dependencies: [
        .module(.coreNetwork),
        .module(.coreStorage),
        .module(.coreModels),
        .module(.coreDesignSystem)
    ]
)
