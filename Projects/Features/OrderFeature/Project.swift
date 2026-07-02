import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .orderFeature,
    dependencies: [
        .module(.tumoNetwork),
        .module(.coreNetwork),
        .module(.coreModels),
        .module(.coreDesignSystem)
    ]
)
