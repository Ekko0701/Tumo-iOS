import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.tumoFramework(
    module: .coreStorage,
    dependencies: [
        .external(.composableArchitecture)
    ]
)
