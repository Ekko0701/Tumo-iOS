import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .stockFeature,
    dependencies: [
        .module(.coreNetwork),
        .module(.coreModels),
        .module(.coreDesignSystem)
    ]
)
