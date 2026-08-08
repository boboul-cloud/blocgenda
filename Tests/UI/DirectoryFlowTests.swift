import XCTest

/// Parcours de l'annuaire : créer une fiche, la ranger dans un tiroir, puis la
/// retrouver par le filtre. Ces tests existent parce qu'il a été signalé, après
/// une création ou un import, que le choix d'un groupe laissait la liste vide
/// jusqu'au redémarrage — de façon intermittente.
final class DirectoryFlowTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()
    }

    // MARK: - Outils

    /// Un suffixe différent à chaque exécution : l'application conserve ses
    /// données d'un lancement à l'autre.
    private func uniqueSuffix() -> String {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
        var n = Int(Date().timeIntervalSince1970 * 100) % (26 * 26 * 26 * 26)
        var suffix = ""
        for _ in 0..<4 {
            suffix.append(alphabet[n % 26])
            n /= 26
        }
        return suffix
    }

    private func openDirectory() {
        let onglet = app.buttons["onglet.directory"]
        XCTAssertTrue(onglet.waitForExistence(timeout: 15), "L'onglet Annuaire est introuvable.")
        onglet.tap()
        XCTAssertTrue(app.buttons["Nouvelle fiche"].waitForExistence(timeout: 10),
                      "Le bouton de nouvelle fiche est introuvable.")
    }

    /// Crée une fiche. `nouveauGroupe` crée le tiroir au passage ;
    /// `groupeExistant` se contente de le choisir dans le classement.
    private func creerFiche(prenom: String,
                            nouveauGroupe: String? = nil,
                            groupeExistant: String? = nil) {
        app.buttons["Nouvelle fiche"].tap()

        let champPrenom = app.textFields["Prénom"]
        XCTAssertTrue(champPrenom.waitForExistence(timeout: 10), "L'éditeur de fiche ne s'ouvre pas.")
        champPrenom.tap()
        champPrenom.typeText(prenom)

        if let nouveauGroupe {
            app.buttons["Nouveau groupe…"].tap()
            let champGroupe = app.textFields["Nom du groupe"]
            XCTAssertTrue(champGroupe.waitForExistence(timeout: 10),
                          "L'alerte de nouveau groupe ne s'ouvre pas.")
            champGroupe.typeText(nouveauGroupe)
            app.buttons["Ajouter"].tap()
        } else if let groupeExistant {
            let selecteur = app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH 'Groupe'")).firstMatch
            XCTAssertTrue(selecteur.waitForExistence(timeout: 5),
                          "Le sélecteur de groupe est absent de l'éditeur.")
            selecteur.tap()
            let choix = app.buttons[groupeExistant]
            XCTAssertTrue(choix.waitForExistence(timeout: 5),
                          "Le groupe « \(groupeExistant) » n'est pas proposé au classement.")
            choix.tap()
        }

        app.buttons["Enregistrer"].tap()
        XCTAssertTrue(app.buttons["Nouvelle fiche"].waitForExistence(timeout: 10),
                      "L'éditeur ne se referme pas après l'enregistrement.")
    }

    /// Ouvre le filtre et relève ses entrées, puis le referme.
    @discardableResult
    private func entreesDuFiltre() -> [String] {
        app.buttons["Filtrer par groupe"].tap()
        let repere = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Tous les groupes ('")).firstMatch
        XCTAssertTrue(repere.waitForExistence(timeout: 8), "Le filtre par groupe ne s'ouvre pas.")
        let entrees = app.buttons.allElementsBoundByIndex
            .map(\.label)
            .filter { $0.contains(" (") && $0.hasSuffix(")") }
        fermerLeMenu()
        return entrees
    }

    /// Referme un menu ouvert en tapant à côté, puis laisse l'animation finir.
    private func fermerLeMenu() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.965)).tap()
        _ = app.buttons["Nouvelle fiche"].waitForExistence(timeout: 5)
        sleep(1)
    }

    /// Affiche un tiroir seul.
    private func filtrerSur(_ groupe: String) {
        app.buttons["Filtrer par groupe"].tap()
        let entree = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", groupe + " (")).firstMatch
        XCTAssertTrue(entree.waitForExistence(timeout: 8),
                      "Le tiroir « \(groupe) » n'est pas proposé au filtre.")
        entree.tap()
    }

    // MARK: - Les parcours

    /// Le cas nominal : une fiche, un tiroir neuf, on la retrouve aussitôt —
    /// dans sa section, dans le filtre, et une fois le filtre appliqué.
    func testCreerUneFicheDansUnNouveauGroupe() throws {
        openDirectory()
        let suffixe = uniqueSuffix()
        let prenom = "Fiche\(suffixe)"
        let groupe = "Tiroir\(suffixe)"

        creerFiche(prenom: prenom, nouveauGroupe: groupe)

        XCTAssertTrue(app.staticTexts[prenom].waitForExistence(timeout: 5),
                      "La fiche créée n'apparaît pas dans l'annuaire.")

        filtrerSur(groupe)
        XCTAssertTrue(app.staticTexts[prenom].waitForExistence(timeout: 5),
                      "Le filtre du groupe ne retrouve pas la fiche qu'il contient.")
    }

    /// Le filtre a déjà été consulté avant la création : rouvert, il doit tenir
    /// compte de ce qui est arrivé depuis, sans redémarrage.
    func testLeFiltreSuitLesCreationsSansRedemarrage() throws {
        openDirectory()
        let suffixe = uniqueSuffix()
        let groupe = "Tiroir\(suffixe)"

        // Une première consultation, avant toute création.
        let avant = entreesDuFiltre()
        XCTAssertFalse(avant.contains { $0.hasPrefix("\(groupe) (") },
                       "Le tiroir ne devrait pas encore exister.")

        creerFiche(prenom: "Un\(suffixe)", nouveauGroupe: groupe)

        // Rouvert, le filtre doit connaître le tiroir et compter sa fiche.
        let apres = entreesDuFiltre()
        XCTAssertTrue(apres.contains("\(groupe) (1)"),
                      "Le filtre rouvert ignore le groupe créé depuis : \(apres)")

        // Une seconde fiche dans le même tiroir : le compte doit suivre.
        creerFiche(prenom: "Deux\(suffixe)", groupeExistant: groupe)
        let final = entreesDuFiltre()
        XCTAssertTrue(final.contains("\(groupe) (2)"),
                      "Le filtre ne compte pas la seconde fiche : \(final)")

        filtrerSur(groupe)
        XCTAssertTrue(app.staticTexts["Un\(suffixe)"].waitForExistence(timeout: 5),
                      "La première fiche du tiroir a disparu du filtre.")
        XCTAssertTrue(app.staticTexts["Deux\(suffixe)"].exists,
                      "La seconde fiche du tiroir a disparu du filtre.")
    }

    /// Une fiche ajoutée alors que son tiroir est déjà affiché seul doit y
    /// paraître sans qu'on lève le filtre.
    func testAjouterUneFicheAlorsQuUnGroupeEstFiltre() throws {
        openDirectory()
        let suffixe = uniqueSuffix()
        let groupe = "Tiroir\(suffixe)"

        creerFiche(prenom: "Premier\(suffixe)", nouveauGroupe: groupe)
        filtrerSur(groupe)
        XCTAssertTrue(app.staticTexts["Premier\(suffixe)"].waitForExistence(timeout: 5))

        creerFiche(prenom: "Second\(suffixe)", groupeExistant: groupe)
        XCTAssertTrue(app.staticTexts["Second\(suffixe)"].waitForExistence(timeout: 5),
                      "La fiche ajoutée dans le tiroir affiché n'y apparaît pas.")
        XCTAssertTrue(app.staticTexts["Premier\(suffixe)"].exists,
                      "La première fiche du tiroir a disparu.")
    }

    /// Un tiroir accentué doit se ranger à sa place alphabétique, et non
    /// derrière les Z — sinon on cherche longtemps ses fiches.
    func testUnGroupeAccentueSeRetrouve() throws {
        openDirectory()
        let suffixe = uniqueSuffix()
        let groupe = "École\(suffixe)"

        creerFiche(prenom: "Eleve\(suffixe)", nouveauGroupe: groupe)

        filtrerSur(groupe)
        XCTAssertTrue(app.staticTexts["Eleve\(suffixe)"].waitForExistence(timeout: 5),
                      "Le filtre d'un tiroir accentué ne retrouve pas sa fiche.")
    }
}
