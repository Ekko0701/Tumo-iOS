import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFramework(
    module: .tumoNetwork,
    dependencies: [
        .module(.coreNetwork),
        .module(.coreStorage)
    ]
)
