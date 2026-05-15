import ProjectDescription

public extension Settings {
    static let tumoDefault: Settings = .settings(
        base: [
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
            "SWIFT_VERSION": "6.0"
        ]
    )
}
