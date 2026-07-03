import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .homeFeature,
    dependencies: [
        .module(.stockFeature),
        .module(.orderFeature),
        .module(.coreDesignSystem)
    ]
)
