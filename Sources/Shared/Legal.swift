import Foundation

/// Adresses publiques et mentions de l'application, rassemblées en un seul
/// endroit : elles apparaissent dans les réglages et dans la fiche App Store,
/// et doivent rester identiques partout.
enum Legal {
    static let siteBase = "https://boboul-cloud.github.io/blocgenda"

    static let site = URL(string: siteBase)!
    static let privacy = URL(string: "\(siteBase)/confidentialite.html")!
    static let terms = URL(string: "\(siteBase)/conditions.html")!
    static let support = URL(string: "\(siteBase)/assistance.html")!
    static let sources = URL(string: "https://github.com/boboul-cloud/blocgenda")!

    static let contactEmail = "bob.oulhen@gmail.com"

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    static var versionString: String { "\(version) (\(build))" }

    static let copyright = "© 2026 Blocgenda. Tous droits réservés."
}
