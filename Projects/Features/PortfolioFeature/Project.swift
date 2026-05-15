import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .portfolioFeature,
    dependencies: [
        .module(.coreNetwork),
        .module(.coreModels),
        .module(.coreDesignSystem)
    ]
)
