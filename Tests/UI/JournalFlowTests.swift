import XCTest

/// Parcours du journal du jour : déposer un moment, le voir mis en page, et
/// changer d'humeur sans rien perdre de ce qui a été écrit.
///
/// Ce qui est vérifié ici n'est pas l'allure de la feuille mais le contrat du
/// moteur : en humeur posée les moments sont cousus (majuscule et point) ; en
/// humeur vive ils restent tels quels, l'heure en marge. Une humeur ne doit
/// jamais réécrire le texte de façon irréversible.
final class JournalFlowTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()
    }

    // MARK: - Outils

    /// L'application conserve ses pages d'un lancement à l'autre : chaque
    /// exécution écrit un mot qui n'appartient qu'à elle.
    private func motUnique() -> String {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
        var n = Int(Date().timeIntervalSince1970 * 100) % (26 * 26 * 26 * 26)
        var mot = ""
        for _ in 0..<4 {
            mot.append(alphabet[n % 26])
            n /= 26
        }
        return mot
    }

    private func ouvrirLeJournal() {
        let onglet = app.buttons["onglet.journal"]
        XCTAssertTrue(onglet.waitForExistence(timeout: 15), "L'onglet Journal est introuvable.")
        onglet.tap()
        XCTAssertTrue(app.textFields["journal.saisie"].waitForExistence(timeout: 10),
                      "La barre du journal ne s'affiche pas.")
    }

    private func deposer(_ texte: String) {
        let barre = app.textFields["journal.saisie"]
        barre.tap()
        barre.typeText(texte)
        app.buttons["journal.deposer"].tap()
    }

    private func choisirLHumeur(_ humeur: String) {
        let bouton = app.buttons["journal.humeur.\(humeur)"]
        XCTAssertTrue(bouton.waitForExistence(timeout: 5),
                      "L'humeur « \(humeur) » n'est pas proposée.")
        bouton.tap()
    }

    /// Vrai si la page porte un texte qui contient ce fragment.
    private func pagePorte(_ fragment: String, timeout: TimeInterval = 5) -> Bool {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", fragment))
            .firstMatch
            .waitForExistence(timeout: timeout)
    }

    // MARK: - Les parcours

    /// Un moment déposé apparaît sur la feuille, cousu comme le veut l'humeur
    /// posée : une majuscule au départ, un point à l'arrivée.
    func testDeposerUnMomentEtLeVoirCousu() throws {
        ouvrirLeJournal()
        let mot = motUnique()
        choisirLHumeur("posee")
        deposer("pluie fine sur \(mot)")

        XCTAssertTrue(pagePorte("Pluie fine sur \(mot)."),
                      "Le moment déposé n'est pas cousu sur la page en humeur posée.")
    }

    /// Changer d'humeur remet la page en page sans toucher au texte : en
    /// humeur vive le moment se relit tel qu'il a été écrit, l'heure en marge.
    func testChangerDHumeurNeReecritPasLeTexte() throws {
        ouvrirLeJournal()
        let mot = motUnique()
        choisirLHumeur("posee")
        deposer("vent d'ouest sur \(mot)")
        XCTAssertTrue(pagePorte("Vent d'ouest sur \(mot)."))

        choisirLHumeur("vive")
        XCTAssertTrue(pagePorte("vent d'ouest sur \(mot)"),
                      "En humeur vive, le moment devrait se relire tel qu'il a été écrit.")
        XCTAssertTrue(app.staticTexts.containing(
            NSPredicate(format: "label MATCHES %@", "\\d{2}h\\d{2}")).firstMatch.exists,
                      "L'heure du moment devrait figurer en marge en humeur vive.")

        // Et l'on revient à la mise en page cousue sans rien avoir perdu.
        choisirLHumeur("posee")
        XCTAssertTrue(pagePorte("Vent d'ouest sur \(mot)."),
                      "Le retour à l'humeur posée devrait retrouver la page cousue.")
    }

    /// La liste des moments montre ce qui a été déposé, dans son état brut, et
    /// permet de retirer une ligne — c'est là qu'on corrige une dictée.
    func testRelireEtEffacerUnMoment() throws {
        ouvrirLeJournal()
        let mot = motUnique()
        choisirLHumeur("posee")
        deposer("brume sur \(mot)")
        XCTAssertTrue(pagePorte("Brume sur \(mot)."))

        app.buttons["journal.moments"].tap()
        let ligne = app.textViews.containing(
            NSPredicate(format: "value CONTAINS %@", mot)).firstMatch
        let champ = ligne.exists ? ligne : app.textFields.containing(
            NSPredicate(format: "value CONTAINS %@", mot)).firstMatch
        XCTAssertTrue(champ.waitForExistence(timeout: 5),
                      "Le moment déposé ne figure pas dans la liste des moments.")

        champ.swipeLeft()
        let effacer = app.buttons["Effacer"]
        XCTAssertTrue(effacer.waitForExistence(timeout: 5),
                      "Le geste d'effacement n'est pas proposé.")
        effacer.tap()
        app.buttons["Fermer"].tap()

        XCTAssertFalse(pagePorte("Brume sur \(mot).", timeout: 3),
                       "Le moment effacé reste sur la page.")
    }
}
