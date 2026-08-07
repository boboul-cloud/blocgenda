import XCTest

/// Pilote réellement l'application pour vérifier les parcours de saisie.
/// Ces tests existent parce qu'un bug de saisie a été signalé depuis l'agenda :
/// mieux vaut une machine qui appuie sur les boutons qu'une relecture de code.
final class AgendaFlowTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()
    }

    // MARK: - Outils

    private func openAgenda() {
        let onglet = app.buttons["onglet.agenda"]
        XCTAssertTrue(onglet.waitForExistence(timeout: 10), "L'onglet Agenda est introuvable.")
        onglet.tap()
        XCTAssertTrue(app.buttons["agenda.nouveau"].waitForExistence(timeout: 5),
                      "Le bouton d'ajout de l'agenda est introuvable.")
    }

    /// Un intitulé différent à chaque exécution : l'app conserve ses données
    /// entre deux lancements, on ne veut pas retomber sur celui d'avant.
    ///
    /// Le suffixe est volontairement composé de lettres : un suffixe chiffré
    /// serait — à juste titre — interprété comme un montant par la barre, et
    /// la ligne s'afficherait amputée de son nombre.
    /// Reproduit le formatage des montants de l'application, pour que les
    /// assertions portent sur la chaîne réellement affichée.
    static func montant(_ value: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = true
        return f.string(from: NSNumber(value: value)) ?? String(value)
    }

    private func uniqueTitle(_ prefix: String) -> String {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
        var n = Int(Date().timeIntervalSince1970) % (26 * 26 * 26)
        var suffix = ""
        for _ in 0..<3 {
            suffix.append(alphabet[n % 26])
            n /= 26
        }
        return "\(prefix) \(suffix)"
    }

    // MARK: - Le parcours signalé comme défaillant

    func testCreerUnRendezVousDepuisLAgenda() throws {
        openAgenda()
        let titre = uniqueTitle("Essai agenda")

        app.buttons["agenda.nouveau"].tap()

        let champ = app.textFields["editeur.titre"]
        XCTAssertTrue(champ.waitForExistence(timeout: 5),
                      "L'éditeur de rendez-vous ne s'ouvre pas depuis l'agenda.")

        champ.tap()
        XCTAssertTrue(champ.waitForExistence(timeout: 2))
        champ.typeText(titre)
        XCTAssertEqual(champ.value as? String, titre,
                       "Le champ d'intitulé n'enregistre pas la frappe.")

        app.buttons["editeur.enregistrer"].tap()

        XCTAssertTrue(app.staticTexts[titre].waitForExistence(timeout: 5),
                      "Le rendez-vous saisi n'apparaît pas dans la journée.")
    }

    func testSaisirLeLieuEtLesNotesDUnRendezVous() throws {
        openAgenda()
        let titre = uniqueTitle("Essai lieu")

        app.buttons["agenda.nouveau"].tap()
        XCTAssertTrue(app.textFields["editeur.titre"].waitForExistence(timeout: 5))

        app.textFields["editeur.titre"].tap()
        app.textFields["editeur.titre"].typeText(titre)

        let lieu = app.textFields["editeur.lieu"]
        XCTAssertTrue(lieu.exists, "Le champ Lieu est absent.")
        lieu.tap()
        lieu.typeText("Portsall")
        XCTAssertEqual(lieu.value as? String, "Portsall",
                       "Le champ Lieu n'enregistre pas la frappe.")

        app.buttons["editeur.enregistrer"].tap()
        XCTAssertTrue(app.staticTexts[titre].waitForExistence(timeout: 5))
    }

    /// La barre du rouleau doit aussi fonctionner depuis l'agenda.
    func testSaisirUneLigneDepuisLaBarreDeLAgenda() throws {
        openAgenda()
        let texte = uniqueTitle("Note agenda")

        let barre = app.textViews["barre.saisie"].exists
            ? app.textViews["barre.saisie"]
            : app.textFields["barre.saisie"]
        XCTAssertTrue(barre.waitForExistence(timeout: 5),
                      "Il n'y a pas de barre de saisie sur l'écran Agenda.")

        barre.tap()
        barre.typeText(texte)
        app.buttons["barre.valider"].tap()

        XCTAssertTrue(app.staticTexts[texte].waitForExistence(timeout: 5),
                      "La ligne saisie depuis l'agenda n'apparaît pas.")
    }

    /// Un calcul saisi depuis l'agenda part sur la bande, mais n'encombre pas
    /// la journée : sa place est dans la colonne de chiffres du rouleau.
    func testUnCalculNApparaitPasDansLAgenda() throws {
        openAgenda()

        let barre = app.textViews["barre.saisie"].exists
            ? app.textViews["barre.saisie"]
            : app.textFields["barre.saisie"]
        XCTAssertTrue(barre.waitForExistence(timeout: 5))

        barre.tap()
        barre.typeText("1234 + 4321")
        app.buttons["barre.valider"].tap()

        // L'opération s'imprime telle quelle ; le résultat, lui, est mis en forme
        // à la française — séparateur de milliers compris, qui n'est pas une
        // espace ordinaire mais une espace fine insécable.
        let operation = "1234 + 4321"
        let resultat = Self.montant(5555)

        func present(_ fragment: String) -> XCUIElement {
            app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS %@", fragment)).firstMatch
        }

        XCTAssertFalse(present(resultat).waitForExistence(timeout: 3),
                       "Le résultat d'un calcul ne doit pas s'afficher dans l'agenda.")
        XCTAssertFalse(present(operation).exists,
                       "L'opération ne doit pas s'afficher dans l'agenda.")

        // Mais elle doit bien être arrivée sur le rouleau : rien n'est perdu.
        app.buttons["onglet.roll"].tap()
        XCTAssertTrue(present(operation).waitForExistence(timeout: 5),
                      "Le calcul saisi depuis l'agenda devrait figurer sur le rouleau.")
        XCTAssertTrue(present(resultat).exists,
                      "Son résultat devrait figurer sur le rouleau.")
    }

    /// Les étiquettes doivent se découvrir sans mode d'emploi : dès que la
    /// barre a le focus, une rangée les propose.
    func testEtiqueterUneLigneDepuisLaRangee() throws {
        app.buttons["onglet.roll"].tap()

        let barre = app.textViews["barre.saisie"].exists
            ? app.textViews["barre.saisie"]
            : app.textFields["barre.saisie"]
        XCTAssertTrue(barre.waitForExistence(timeout: 5))
        barre.tap()

        let bouton = app.buttons["barre.etiquette"]
        XCTAssertTrue(bouton.waitForExistence(timeout: 3),
                      "La rangée d'étiquettes devrait apparaître dès qu'on écrit.")

        barre.typeText(uniqueTitle("Essence"))
        bouton.tap()                 // insère le dièse
        barre.typeText("bateau")
        app.buttons["barre.valider"].tap()

        XCTAssertTrue(app.staticTexts["#bateau"].waitForExistence(timeout: 5),
                      "L'étiquette saisie devrait s'imprimer sous la ligne.")

        // Une fois employée, elle est proposée d'un seul geste la fois d'après.
        barre.tap()
        XCTAssertTrue(app.buttons["#bateau"].waitForExistence(timeout: 3),
                      "L'étiquette déjà employée devrait être proposée dans la rangée.")
    }

    // MARK: - Le même parcours depuis le rouleau, pour comparaison

    func testSaisirUneLigneDepuisLeRouleau() throws {
        let onglet = app.buttons["onglet.roll"]
        XCTAssertTrue(onglet.waitForExistence(timeout: 10))
        onglet.tap()

        let texte = uniqueTitle("Note rouleau")
        let barre = app.textViews["barre.saisie"].exists
            ? app.textViews["barre.saisie"]
            : app.textFields["barre.saisie"]
        XCTAssertTrue(barre.waitForExistence(timeout: 5))

        barre.tap()
        barre.typeText(texte)
        app.buttons["barre.valider"].tap()

        XCTAssertTrue(app.staticTexts[texte].waitForExistence(timeout: 5),
                      "La ligne saisie depuis le rouleau n'apparaît pas.")
    }
}
