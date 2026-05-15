import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .orderFeature,
    dependencies: [
        .module(.coreNetwork),
        .module(.coreModels),
        .module(.coreDesignSystem)
    ]
)
