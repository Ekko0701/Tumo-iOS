import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoApp(
    dependencies: [
        .module(.coreNetwork),
        .module(.coreStorage),
        .module(.coreModels),
        .module(.coreDesignSystem),
        .module(.authFeature),
        .module(.stockFeature),
        .module(.orderFeature),
        .module(.portfolioFeature)
    ]
)
