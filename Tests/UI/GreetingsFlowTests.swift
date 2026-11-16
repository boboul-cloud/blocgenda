import XCTest

/// Parcours des souhaits d'anniversaire et de fête.
///
/// Ce qui est vérifié ici est la règle qui borde la fonction : **rien ne se
/// prépare tant qu'aucun groupe n'est coché**. Un envoi automatique qui
/// partirait à tout l'annuaire serait la pire des régressions — mieux vaut la
/// voir en test qu'en recevant les messages.
final class GreetingsFlowTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Outils

    /// Ouvre Réglages ▸ Annuaire ▸ Souhaits.
    private func ouvrirLesSouhaits() {
        let reglages = app.buttons["Réglages"]
        XCTAssertTrue(reglages.waitForExistence(timeout: 15), "Le bouton des réglages est introuvable.")
        reglages.tap()

        let ligne = app.descendants(matching: .any)["reglages.souhaits"]
        XCTAssertTrue(descendreJusqua(ligne), "La ligne « Souhaits » manque aux réglages.")
        ligne.tap()

        XCTAssertTrue(interrupteur.waitForExistence(timeout: 10), "L'écran des souhaits ne s'ouvre pas.")
    }

    /// Les formulaires sont des listes paresseuses : ce qui n'a jamais paru à
    /// l'écran n'existe pas encore, et ce qui en est sorti n'existe plus. Les
    /// deux sens servent donc, l'un pour descendre aux groupes, l'autre pour
    /// remonter à l'interrupteur.
    @discardableResult
    private func defilerJusqua(_ element: XCUIElement, vers bas: Bool, tries: Int) -> Bool {
        let liste = app.collectionViews.firstMatch
        for _ in 0..<tries {
            if element.exists, element.isHittable { return true }
            if liste.exists {
                bas ? liste.swipeUp() : liste.swipeDown()
            } else {
                bas ? app.swipeUp() : app.swipeDown()
            }
        }
        return element.exists && element.isHittable
    }

    @discardableResult
    private func descendreJusqua(_ element: XCUIElement, tries: Int = 10) -> Bool {
        defilerJusqua(element, vers: true, tries: tries)
    }

    @discardableResult
    private func remonterJusqua(_ element: XCUIElement, tries: Int = 10) -> Bool {
        defilerJusqua(element, vers: false, tries: tries)
    }

    private var interrupteur: XCUIElement { app.switches["souhaits.interrupteur"] }

    private var estAllume: Bool { String(describing: interrupteur.value ?? "0") == "1" }

    /// Bascule l'interrupteur — sur sa commande, pas sur sa rangée : un
    /// interrupteur de formulaire ne réagit pas à un appui sur son libellé.
    private func basculer(vers actif: Bool) {
        remonterJusqua(interrupteur, tries: 8)
        guard estAllume != actif else { return }

        let commande = interrupteur.switches.firstMatch
        (commande.exists ? commande : interrupteur).tap()

        var essais = 0
        while estAllume != actif, essais < 15 {
            usleep(200_000)
            essais += 1
        }
        XCTAssertEqual(estAllume, actif, "L'interrupteur des souhaits ne bascule pas.")
    }

    /// Le tiroir « Famille » existe d'office : il sert de cobaye.
    private var famille: XCUIElement { app.descendants(matching: .any)["souhaits.groupe.Famille"] }

    /// Coché ou non : la rangée le dit dans sa valeur d'accessibilité, celle
    /// que lit la synthèse vocale.
    private var familleEstCochee: Bool {
        String(describing: famille.value ?? "") == "Coché"
    }

    private func texte(commencantPar debut: String) -> XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", debut)).firstMatch
    }

    // MARK: - Les parcours

    /// L'écran ne montre ses réglages que lorsqu'on a demandé les souhaits :
    /// fermé, il ne propose rien à cocher.
    func testLesReglagesNApparaissentQueLaFonctionDemandee() throws {
        ouvrirLesSouhaits()
        basculer(vers: false)
        XCTAssertFalse(famille.exists,
                       "Les groupes sont proposés alors que les souhaits sont éteints.")

        basculer(vers: true)
        XCTAssertTrue(descendreJusqua(famille, tries: 4),
                      "Les groupes ne sont pas proposés une fois les souhaits demandés.")

        basculer(vers: false)
    }

    /// Aucun groupe coché, rien ne se prépare — et l'écran le dit.
    func testAucunGroupeCocheNePrepareRien() throws {
        ouvrirLesSouhaits()
        basculer(vers: true)
        XCTAssertTrue(descendreJusqua(famille, tries: 4), "Le tiroir « Famille » manque à la liste.")

        // On part d'un tiroir décoché, quel que soit l'état laissé par un essai
        // précédent : l'application garde ses réglages d'un lancement à l'autre.
        if familleEstCochee { famille.tap() }

        XCTAssertTrue(descendreJusqua(texte(commencantPar: "Aucun groupe coché"), tries: 4),
                      "Rien ne prévient que sans groupe coché, rien ne partira.")

        XCTAssertTrue(remonterJusqua(famille, tries: 4), "Le tiroir « Famille » s'est perdu en route.")
        famille.tap()
        XCTAssertTrue(familleEstCochee, "Le tiroir coché ne se signale pas comme tel.")

        XCTAssertTrue(descendreJusqua(texte(commencantPar: "Seules les fiches"), tries: 4),
                      "L'écran ne dit pas que seuls les tiroirs cochés sont fêtés.")

        // On repart comme on est arrivé : la fonction reste fermée d'origine.
        XCTAssertTrue(remonterJusqua(famille, tries: 4), "Le tiroir « Famille » s'est perdu en route.")
        famille.tap()
        basculer(vers: false)
    }
}
