import Foundation

enum ProductTier: String, CaseIterable {
    case cheap
    case full

    static let storageKey = "easeMirror.productTier"

    static var current: ProductTier {
        get {
            guard let raw = UserDefaults.standard.string(forKey: storageKey),
                  let tier = ProductTier(rawValue: raw) else {
                return .cheap
            }
            return tier
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }

    var label: String {
        switch self {
        case .cheap: "Ghost Mirror"
        case .full: "Developer Mode"
        }
    }
}
