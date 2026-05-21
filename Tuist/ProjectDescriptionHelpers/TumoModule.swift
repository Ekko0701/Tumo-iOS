public enum TumoModule: String, CaseIterable {
    case app = "Tumo"

    case coreNetwork = "CoreNetwork"
    case coreStorage = "CoreStorage"
    case tumoNetwork = "TumoNetwork"
    case coreModels = "CoreModels"
    case coreDesignSystem = "CoreDesignSystem"

    case authFeature = "AuthFeature"
    case stockFeature = "StockFeature"
    case orderFeature = "OrderFeature"
    case portfolioFeature = "PortfolioFeature"

    public var name: String {
        rawValue
    }

    public var testsName: String {
        "\(name)Tests"
    }

    public var demoName: String {
        "\(name)Demo"
    }

    public var projectPath: String {
        switch self {
        case .app:
            "Projects/App"
        case .coreNetwork:
            "Projects/Core/CoreNetwork"
        case .coreStorage:
            "Projects/Core/CoreStorage"
        case .tumoNetwork:
            "Projects/Core/TumoNetwork"
        case .coreModels:
            "Projects/Core/CoreModels"
        case .coreDesignSystem:
            "Projects/Core/CoreDesignSystem"
        case .authFeature:
            "Projects/Features/AuthFeature"
        case .stockFeature:
            "Projects/Features/StockFeature"
        case .orderFeature:
            "Projects/Features/OrderFeature"
        case .portfolioFeature:
            "Projects/Features/PortfolioFeature"
        }
    }

    public var isFeature: Bool {
        switch self {
        case .authFeature, .stockFeature, .orderFeature, .portfolioFeature:
            true
        case .app, .coreNetwork, .coreStorage, .tumoNetwork, .coreModels, .coreDesignSystem:
            false
        }
    }
}
