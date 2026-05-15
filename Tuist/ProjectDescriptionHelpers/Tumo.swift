import ProjectDescription

public enum Tumo {
    public static let appName = "Tumo"
    public static let bundleIdPrefix = "com.tumo"
    public static let appBundleId = "\(bundleIdPrefix).ios"
    public static let deploymentTarget: DeploymentTargets = .iOS("17.0")

    public static func bundleId(for module: TumoModule) -> String {
        switch module {
        case .app:
            appBundleId
        default:
            "\(bundleIdPrefix).\(module.name)"
        }
    }

    public static func testsBundleId(for module: TumoModule) -> String {
        "\(bundleId(for: module)).tests"
    }

    public static func demoBundleId(for module: TumoModule) -> String {
        "\(bundleId(for: module)).demo"
    }
}
