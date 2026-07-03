import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFeature(
    module: .myInfoFeature,
    dependencies: [
        .module(.authFeature),
        .module(.orderFeature),
        .module(.stockFeature),
        .module(.coreDesignSystem)
    ]
)
