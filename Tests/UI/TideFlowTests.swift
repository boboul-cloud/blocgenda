import XCTest

/// La marée doit suivre le lieu choisi en haut de l'écran. Ces tests existent
/// parce qu'elle restait figée : un port de marée épinglé une fois pour toutes
/// continuait de servir, quel que soit le lieu, sans que rien ne le dise.
final class TideFlowTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()
    }

    // MARK: - Outils

    private func ouvrirLeJour() {
        let onglet = app.buttons["onglet.day"]
        XCTAssertTrue(onglet.waitForExistence(timeout: 15), "L'onglet « Le jour » est introuvable.")
        onglet.tap()
        XCTAssertTrue(app.staticTexts["MARÉE"].waitForExistence(timeout: 25),
                      "La fiche Marée n'arrive pas — réseau ?")
    }

    /// Ce que la fiche Marée annonce : le port, puis les heures d'étale.
    private func ficheMaree() -> (port: String?, heures: [String]) {
        let textes = app.staticTexts.allElementsBoundByIndex.map(\.label)
        guard let i = textes.firstIndex(of: "MARÉE") else { return (nil, []) }
        let bloc = Array(textes[i..<min(i + 16, textes.count)])
        let heures = bloc.filter { $0.count == 5 && $0.contains("h") && Int($0.prefix(2)) != nil }
        // La pastille du port précède immédiatement celle de la vive-eau.
        let etats = ["vive-eau", "marée moyenne", "morte-eau"]
        let port = bloc.firstIndex { etats.contains($0) }.flatMap { i in
            i > 0 ? bloc[i - 1] : nil
        }
        return (port, heures)
    }

    private func pastilleDuLieu() -> XCUIElement? {
        app.buttons.allElementsBoundByIndex
            .filter { $0.frame.minY > 40 && $0.frame.minY < 200 && $0.frame.width < 200 }
            .min { $0.frame.minY < $1.frame.minY }
    }

    /// Choisit un port. La pastille du lieu porte le même intitulé que la ligne
    /// de la liste : on vise celle qui est dans la liste, plus bas dans l'écran.
    private func allerA(_ nom: String) {
        guard let pastille = pastilleDuLieu() else { return XCTFail("Pastille du lieu introuvable.") }
        pastille.tap()
        let lignes = app.buttons.matching(NSPredicate(format: "label == %@", nom))
        XCTAssertTrue(lignes.firstMatch.waitForExistence(timeout: 10),
                      "Le port \(nom) n'est pas proposé.")
        let cible = lignes.allElementsBoundByIndex
            .filter { $0.frame.minY > 150 }
            .min { $0.frame.minY < $1.frame.minY } ?? lignes.firstMatch
        cible.tap()
        sleep(14)   // le relevé passe par le réseau
    }

    // MARK: - Les parcours

    /// Deux ports séparés de deux heures et demie de marée : les heures
    /// affichées ne peuvent pas être les mêmes.
    func testChangerDeLieuChangeLesHeures() throws {
        ouvrirLeJour()

        allerA("Brest")
        let brest = ficheMaree()
        XCTAssertFalse(brest.heures.isEmpty, "Aucune heure de marée pour Brest.")

        allerA("Saint-Malo")
        let malo = ficheMaree()
        XCTAssertFalse(malo.heures.isEmpty, "Aucune heure de marée pour Saint-Malo.")

        XCTAssertNotEqual(brest.heures, malo.heures,
                          "Les heures de marée n'ont pas suivi le changement de lieu : \(brest.heures)")
    }

    /// Un port de marée épinglé suit le lieu : il a été choisi comme « le plus
    /// proche », il n'a plus de sens une fois qu'on a déménagé.
    func testUnPortEpingleSuitLeLieu() throws {
        ouvrirLeJour()

        allerA("Brest")
        let avant = ficheMaree()
        XCTAssertFalse(avant.heures.isEmpty)

        // On épingle le port de marée le plus proche.
        pastilleDuLieu()?.tap()
        sleep(1)
        for _ in 0..<12 { app.swipeUp() }
        let epingler = app.buttons["Utiliser le port le plus proche pour la marée"]
        XCTAssertTrue(epingler.waitForExistence(timeout: 10), "Le réglage de marée est introuvable.")
        epingler.tap()
        sleep(14)

        allerA("Saint-Malo")
        let apres = ficheMaree()
        XCTAssertFalse(apres.heures.isEmpty, "Plus aucune heure après le changement de lieu.")
        XCTAssertNotEqual(avant.heures, apres.heures,
                          "Le port épinglé fige la marée : elle est restée à \(avant.heures).")
        XCTAssertEqual(apres.port, "Saint-Malo",
                       "La fiche annonce encore « \(apres.port ?? "—") ».")
    }
}
