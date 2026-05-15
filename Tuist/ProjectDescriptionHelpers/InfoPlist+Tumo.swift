import ProjectDescription

public extension InfoPlist {
    static let tumoApp: InfoPlist = .extendingDefault(with: [
        "CFBundleDisplayName": .string(Tumo.appName),
        "ITSAppUsesNonExemptEncryption": .boolean(false),
        "UILaunchScreen": .dictionary([:])
    ])

    static func tumoDemoApp(module: TumoModule) -> InfoPlist {
        .extendingDefault(with: [
            "CFBundleDisplayName": .string(module.demoName),
            "ITSAppUsesNonExemptEncryption": .boolean(false),
            "UILaunchScreen": .dictionary([:])
        ])
    }
}
