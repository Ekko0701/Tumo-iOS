import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoApp(
    dependencies: [
        .external(.composableArchitecture),
        .module(.coreStorage),
        .module(.coreModels),
        .module(.coreDesignSystem),
        .module(.authFeature),
        .module(.stockFeature),
        .module(.orderFeature),
        .module(.portfolioFeature),
        .module(.homeFeature),
        .module(.myInfoFeature)
    ]
)
