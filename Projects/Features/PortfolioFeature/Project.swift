import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .portfolioFeature,
    dependencies: [
        .module(.tumoNetwork),
        .module(.coreModels),
        .module(.coreDesignSystem)
    ]
)
