import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .orderFeature,
    dependencies: [
        .module(.tumoNetwork),
        .module(.coreModels),
        .module(.coreDesignSystem)
    ]
)
