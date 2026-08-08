import XCTest

/// Prend les captures d'écran de la fiche App Store.
///
/// Piloter l'application depuis le terminal ne suffit pas : la demande
/// d'autorisation des notifications masquerait la première image, un lien
/// profond envoyé par `simctl` fait apparaître une confirmation système, et
/// aucune commande ne sait ouvrir le clavier pour montrer la barre en action.
/// Un test d'interface, lui, appuie où il faut.
///
/// Le contenu affiché vient de `Tools/captures-seed.py` : ce test ne crée
/// aucune donnée. Tout est enchaîné par `Tools/captures.sh`.
final class CaptureTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()
        allowNotifications()
    }

    // MARK: - Fenêtres du système

    /// La demande d'autorisation est posée par le système, pas par l'app : elle
    /// n'appartient donc pas à `app` mais à SpringBoard.
    private func allowNotifications() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Autoriser", "Allow"] {
            let bouton = springboard.buttons[label]
            if bouton.waitForExistence(timeout: 5) {
                bouton.tap()
                return
            }
        }
    }

    /// Le clavier s'ouvre la première fois sur une présentation de ses langues.
    /// Elle occupe toute sa place et ruinerait la capture.
    private func dismissKeyboardIntro() {
        for label in ["Continue", "Continuer", "Terminé", "Done"] {
            let button = app.buttons[label]
            if button.waitForExistence(timeout: 3) {
                button.tap()
                return
            }
        }
    }

    private func shoot(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func open(_ tab: String, wait: TimeInterval = 2.5) {
        let onglet = app.buttons["onglet.\(tab)"]
        XCTAssertTrue(onglet.waitForExistence(timeout: 15), "L'onglet \(tab) est introuvable.")
        onglet.tap()
        Thread.sleep(forTimeInterval: wait)
    }

    // MARK: - La série

    func testPrendreLesCaptures() throws {
        // 1. Le rouleau tel qu'on le retrouve en ouvrant l'app.
        open("roll")
        shoot("1-rouleau")

        // 2. La barre en action : on écrit en toutes lettres, l'étiquette
        //    annonce ce qui a été compris avant même de valider.
        let barre = app.textViews["barre.saisie"].exists
            ? app.textViews["barre.saisie"]
            : app.textFields["barre.saisie"]
        XCTAssertTrue(barre.waitForExistence(timeout: 5), "La barre de saisie est introuvable.")
        barre.tap()
        dismissKeyboardIntro()
        barre.tap()
        barre.typeText("demain 14h30 dentiste")
        Thread.sleep(forTimeInterval: 2)
        shoot("2-barre-active")

        // Repartir d'une application propre plutôt que d'effacer à la main.
        app.terminate()
        app.launch()

        // 3. Le jour : soleil, marée, lune. La marée vient du réseau.
        open("day", wait: 9)
        shoot("3-jour")

        // 4. L'agenda des sept jours.
        open("agenda")
        shoot("4-agenda")

        // 5. L'annuaire.
        open("directory")
        shoot("5-annuaire")
    }
}
