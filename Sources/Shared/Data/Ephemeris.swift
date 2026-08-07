import Foundation

/// L'éphéméride du jour : saint, dicton, événement historique, repères de l'année.
/// Tout est embarqué dans l'app — aucune connexion n'est nécessaire.
struct Ephemeris: Hashable, Sendable {
    var date: Date
    var saint: String
    var dicton: String
    var historicalEvents: [String]
    var dayOfYear: Int
    var daysRemaining: Int
    var weekNumber: Int
    var isHoliday: Bool
    var holidayName: String?

    var dayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMMM yyyy"
        return f.string(from: date).capitalizedFirst
    }

    static func forDay(_ date: Date) -> Ephemeris {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        let doy = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let inYear = cal.range(of: .day, in: .year, for: date)?.count ?? 365
        let key = String(format: "%02d-%02d", month, day)
        let holiday = FrenchHolidays.name(for: date)

        return Ephemeris(
            date: date,
            saint: SaintsCalendar.saint(month: month, day: day),
            dicton: Dictons.forDay(month: month, day: day),
            historicalEvents: HistoricalEvents.table[key] ?? [],
            dayOfYear: doy,
            daysRemaining: inYear - doy,
            weekNumber: cal.component(.weekOfYear, from: date),
            isHoliday: holiday != nil,
            holidayName: holiday)
    }
}

// MARK: - Saints du jour

enum SaintsCalendar {
    static func saint(month: Int, day: Int) -> String {
        guard month >= 1, month <= 12 else { return "" }
        let list = table[month - 1]
        guard day >= 1, day <= list.count else { return "" }
        return list[day - 1]
    }

    /// Calendrier « des postes », douze tableaux de 28 à 31 entrées.
    static let table: [[String]] = [
        // Janvier
        ["Jour de l’An", "Basile", "Geneviève", "Odilon", "Édouard", "Mélaine", "Raymond", "Lucien",
         "Alix", "Guillaume", "Paulin", "Tatiana", "Yvette", "Nina", "Rémi", "Marcel", "Roseline",
         "Prisca", "Marius", "Sébastien", "Agnès", "Vincent", "Barnard", "François de Sales",
         "Conversion de Paul", "Paule", "Angèle", "Thomas d’Aquin", "Gildas", "Martine", "Marcelle"],
        // Février
        ["Ella", "Chandeleur", "Blaise", "Véronique", "Agathe", "Gaston", "Eugénie", "Jacqueline",
         "Apolline", "Arnaud", "Notre-Dame de Lourdes", "Félix", "Béatrice", "Valentin", "Claude",
         "Julienne", "Alexis", "Bernadette", "Gabin", "Aimée", "Pierre-Damien", "Isabelle", "Lazare",
         "Modeste", "Roméo", "Nestor", "Honorine", "Romain", "Auguste"],
        // Mars
        ["Aubin", "Charles le Bon", "Guénolé", "Casimir", "Olive", "Colette", "Félicité",
         "Jean de Dieu", "Françoise", "Vivien", "Rosine", "Justine", "Rodrigue", "Mathilde", "Louise",
         "Bénédicte", "Patrice", "Cyrille", "Joseph", "Herbert", "Clémence", "Léa", "Victorien",
         "Catherine de Suède", "Annonciation", "Larissa", "Habib", "Gontran", "Gwladys", "Amédée", "Benjamin"],
        // Avril
        ["Hugues", "Sandrine", "Richard", "Isidore", "Irène", "Marcellin", "Jean-Baptiste de la Salle",
         "Julie", "Gautier", "Fulbert", "Stanislas", "Jules", "Ida", "Maxime", "Paterne",
         "Benoît-Joseph", "Anicet", "Parfait", "Emma", "Odette", "Anselme", "Alexandre", "Georges",
         "Fidèle", "Marc", "Alida", "Zita", "Valérie", "Catherine de Sienne", "Robert"],
        // Mai
        ["Fête du Travail", "Boris", "Philippe et Jacques", "Sylvain", "Judith", "Prudence", "Gisèle",
         "Victoire 1945", "Pacôme", "Solange", "Estelle", "Achille", "Rolande", "Matthias", "Denise",
         "Honoré", "Pascal", "Éric", "Yves", "Bernardin", "Constantin", "Émile", "Didier", "Donatien",
         "Sophie", "Bérenger", "Augustin de Cantorbéry", "Germain", "Aymar", "Ferdinand", "Visitation"],
        // Juin
        ["Justin", "Blandine", "Kévin", "Clotilde", "Igor", "Norbert", "Gilbert", "Médard", "Diane",
         "Landry", "Barnabé", "Guy", "Antoine de Padoue", "Élisée", "Germaine", "Jean-François Régis",
         "Hervé", "Léonce", "Romuald", "Silvère", "Rodolphe", "Alban", "Audrey", "Jean-Baptiste",
         "Prosper", "Anthelme", "Fernand", "Irénée", "Pierre et Paul", "Martial"],
        // Juillet
        ["Thierry", "Martinien", "Thomas", "Florent", "Antoine-Marie", "Mariette", "Raoul", "Thibaut",
         "Amandine", "Ulrich", "Benoît", "Olivier", "Henri et Joël", "Fête nationale", "Donald",
         "Notre-Dame du Mont-Carmel", "Charlotte", "Frédéric", "Arsène", "Marina", "Victor",
         "Marie-Madeleine", "Brigitte", "Christine", "Jacques", "Anne et Joachim", "Nathalie",
         "Samson", "Marthe", "Juliette", "Ignace de Loyola"],
        // Août
        ["Alphonse", "Julien Eymard", "Lydie", "Jean-Marie Vianney", "Abel", "Transfiguration",
         "Gaétan", "Dominique", "Amour", "Laurent", "Claire", "Clarisse", "Hippolyte", "Évrard",
         "Assomption", "Armel", "Hyacinthe", "Hélène", "Jean Eudes", "Bernard", "Christophe",
         "Fabrice", "Rose de Lima", "Barthélemy", "Louis", "Natacha", "Monique", "Augustin", "Sabine",
         "Fiacre", "Aristide"],
        // Septembre
        ["Gilles", "Ingrid", "Grégoire", "Rosalie", "Raïssa", "Bertrand", "Reine", "Nativité de Marie",
         "Alain", "Inès", "Adelphe", "Apollinaire", "Aimé", "La Croix Glorieuse", "Roland", "Édith",
         "Renaud", "Nadège", "Émilie", "Davy", "Matthieu", "Maurice", "Constant", "Thècle", "Hermann",
         "Côme et Damien", "Vincent de Paul", "Venceslas", "Michel", "Jérôme"],
        // Octobre
        ["Thérèse de l’Enfant-Jésus", "Léger", "Gérard", "François d’Assise", "Fleur", "Bruno",
         "Serge", "Pélagie", "Denis", "Ghislain", "Firmin", "Wilfried", "Géraud", "Juste",
         "Thérèse d’Avila", "Edwige", "Baudouin", "Luc", "René", "Adeline", "Céline", "Élodie",
         "Jean de Capistran", "Florentin", "Crépin", "Dimitri", "Émeline", "Simon et Jude", "Narcisse",
         "Bienvenue", "Quentin"],
        // Novembre
        ["Toussaint", "Défunts", "Hubert", "Charles Borromée", "Sylvie", "Bertille", "Carine",
         "Geoffroy", "Théodore", "Léon", "Armistice 1918", "Christian", "Brice", "Sidoine", "Albert",
         "Marguerite", "Élisabeth", "Aude", "Tanguy", "Edmond", "Présentation de Marie", "Cécile",
         "Clément", "Flora", "Catherine", "Delphine", "Séverin", "Jacques de la Marche", "Saturnin", "André"],
        // Décembre
        ["Florence", "Viviane", "François-Xavier", "Barbara", "Gérald", "Nicolas", "Ambroise",
         "Immaculée Conception", "Pierre Fourier", "Romaric", "Daniel", "Jeanne-Françoise", "Lucie",
         "Odile", "Ninon", "Alice", "Gaël", "Gatien", "Urbain", "Abraham", "Pierre Canisius",
         "Françoise-Xavière", "Armand", "Adèle", "Noël", "Étienne", "Jean", "Innocents", "David",
         "Roger", "Sylvestre"]
    ]
}

// MARK: - Dictons

enum Dictons {
    static func forDay(month: Int, day: Int) -> String {
        guard month >= 1, month <= 12 else { return "" }
        let pool = table[month - 1]
        guard !pool.isEmpty else { return "" }
        return pool[(day - 1) % pool.count]
    }

    static let table: [[String]] = [
        ["Janvier sec et sage est un bon présage.",
         "Au mois de janvier, mieux vaut voir un loup qu’un paysan en manches de chemise.",
         "Les jours croissent, le froid renaît.",
         "Neige de janvier vaut du fumier."],
        ["À la Chandeleur, l’hiver se meurt ou prend vigueur.",
         "Février le court est le pire de tous.",
         "Quand février commence en lion, il finit comme un mouton.",
         "Pluie de février vaut jus de fumier."],
        ["En mars, quand il fait beau, prends ton manteau.",
         "Mars venteux, verger pommeux.",
         "Taille tôt, taille tard, rien ne vaut la taille de mars.",
         "Brouillard de mars, gelée en mai."],
        ["En avril, ne te découvre pas d’un fil.",
         "Avril pluvieux, mai joyeux.",
         "Quand il tonne en avril, le laboureur se réjouit.",
         "Bourgeon qui pousse en avril met peu de vin au baril."],
        ["En mai, fais ce qu’il te plaît.",
         "Mai frais et venteux fait l’an plantureux.",
         "Rosée de mai verdit la haie.",
         "Au mois de mai, manteau jeté."],
        ["Juin bien fleuri, vrai paradis.",
         "S’il pleut à la Saint-Médard, il pleut quarante jours plus tard.",
         "En juin, trop de pluie, le jardin est démuni.",
         "Beau temps à la Saint-Jean, blé abondant."],
        ["Juillet sans orage, famine au village.",
         "En juillet, la faucille au poignet.",
         "Chaleur de juillet fait la richesse du grenier.",
         "Petite pluie de juillet ruine le blé."],
        ["Août mûrit, septembre vendange.",
         "Quand il pleut à la Saint-Laurent, la pluie vient à temps.",
         "Ce que le mois d’août ne cuit pas, septembre ne le rôtit pas.",
         "Brouillard d’août, chaleur pour tout."],
        ["Septembre humide, pas de tonneau vide.",
         "En septembre, si tu es prudent, achète grains et vêtements.",
         "Beau septembre remplit les greniers.",
         "Tonnerre de septembre annonce un bel hiver."],
        ["En octobre, qui n’a pas de vêtements en dur souffre du froid.",
         "Brouillards d’octobre et pluvieux novembre font bon décembre.",
         "En octobre, tonnerre, vendanges prospères.",
         "Quand octobre prend sa fin, la Toussaint est le lendemain."],
        ["À la Sainte-Catherine, tout bois prend racine.",
         "À la Saint-Martin, l’hiver est en chemin.",
         "Novembre chaud et pluvieux annonce un hiver rigoureux.",
         "Brouillard de novembre, cheminée qui fume."],
        ["Décembre trop beau, été dans l’eau.",
         "Noël au balcon, Pâques aux tisons.",
         "Neige de décembre est engrais pour la terre.",
         "Décembre ensoleillé, été mouillé."]
    ]
}

// MARK: - Jours fériés

enum FrenchHolidays {
    /// Dimanche de Pâques par l'algorithme de Butcher.
    static func easter(year: Int) -> Date? {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func name(for date: Date) -> String? {
        let cal = Calendar.current
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)

        let fixed: [String: String] = [
            "01-01": "Jour de l’An", "05-01": "Fête du Travail", "05-08": "Victoire 1945",
            "07-14": "Fête nationale", "08-15": "Assomption", "11-01": "Toussaint",
            "11-11": "Armistice 1918", "12-25": "Noël"
        ]
        if let n = fixed[String(format: "%02d-%02d", month, day)] { return n }

        guard let easter = easter(year: year) else { return nil }
        let movable: [(Int, String)] = [
            (1, "Lundi de Pâques"), (39, "Ascension"), (50, "Lundi de Pentecôte")
        ]
        for (offset, label) in movable {
            if let d = cal.date(byAdding: .day, value: offset, to: easter),
               cal.isDate(d, inSameDayAs: date) { return label }
        }
        if cal.isDate(easter, inSameDayAs: date) { return "Pâques" }
        return nil
    }
}

// MARK: - Ce jour-là

enum HistoricalEvents {
    /// Sélection d'événements marquants, indexés « MM-JJ ».
    static let table: [String: [String]] = [
        "01-01": ["1999 — L’euro devient la monnaie unique de onze pays européens."],
        "01-03": ["1888 — Le premier brevet de la paille à boire est déposé."],
        "01-07": ["1610 — Galilée observe les quatre principales lunes de Jupiter."],
        "01-15": ["1929 — Naissance de Martin Luther King."],
        "01-21": ["1793 — Louis XVI est guillotiné place de la Révolution."],
        "01-25": ["1924 — Ouverture des premiers Jeux olympiques d’hiver, à Chamonix."],
        "01-27": ["1945 — Libération du camp d’Auschwitz."],
        "02-02": ["1848 — Fin de la guerre américano-mexicaine."],
        "02-11": ["1990 — Nelson Mandela est libéré après 27 ans de détention."],
        "02-12": ["1809 — Naissance de Charles Darwin."],
        "02-14": ["1876 — Alexander Graham Bell dépose le brevet du téléphone."],
        "02-21": ["1848 — Publication du Manifeste du parti communiste."],
        "02-28": ["1953 — Watson et Crick décrivent la double hélice de l’ADN."],
        "03-04": ["1861 — Abraham Lincoln devient président des États-Unis."],
        "03-12": ["1989 — Tim Berners-Lee propose le projet qui deviendra le Web."],
        "03-15": ["-44 — Assassinat de Jules César aux ides de mars."],
        "03-18": ["1871 — Début de la Commune de Paris."],
        "03-31": ["1889 — Inauguration de la tour Eiffel."],
        "04-04": ["1949 — Signature du traité de l’Atlantique Nord."],
        "04-12": ["1961 — Youri Gagarine est le premier homme dans l’espace."],
        "04-15": ["1912 — Naufrage du Titanic dans l’Atlantique Nord.",
                  "2019 — Incendie de la cathédrale Notre-Dame de Paris."],
        "04-25": ["1974 — Révolution des Œillets au Portugal."],
        "05-08": ["1945 — Capitulation de l’Allemagne nazie, fin de la guerre en Europe."],
        "05-13": ["1888 — Abolition de l’esclavage au Brésil."],
        "05-21": ["1927 — Lindbergh achève la première traversée de l’Atlantique en solitaire."],
        "05-29": ["1953 — Hillary et Tensing atteignent le sommet de l’Everest."],
        "06-06": ["1944 — Débarquement allié en Normandie."],
        "06-18": ["1940 — Appel du général de Gaulle depuis Londres."],
        "06-21": ["1982 — Première Fête de la musique en France."],
        "06-28": ["1919 — Signature du traité de Versailles."],
        "07-04": ["1776 — Déclaration d’indépendance des États-Unis."],
        "07-14": ["1789 — Prise de la Bastille."],
        "07-20": ["1969 — Armstrong et Aldrin marchent sur la Lune."],
        "07-21": ["1969 — Retour du module lunaire d’Apollo 11."],
        "08-06": ["1945 — Bombardement atomique d’Hiroshima."],
        "08-15": ["1769 — Naissance de Napoléon Bonaparte à Ajaccio."],
        "08-19": ["1839 — Présentation publique du daguerréotype à Paris."],
        "08-25": ["1944 — Libération de Paris."],
        "09-02": ["1945 — Capitulation du Japon, fin de la Seconde Guerre mondiale."],
        "09-09": ["1947 — Le premier « bug » informatique, un papillon de nuit, est consigné."],
        "09-19": ["1991 — Découverte d’Ötzi, momie du Néolithique, dans les Alpes."],
        "09-28": ["1928 — Alexander Fleming découvre la pénicilline."],
        "10-01": ["1908 — La Ford T est mise en vente."],
        "10-04": ["1957 — Lancement de Spoutnik 1, premier satellite artificiel."],
        "10-14": ["1947 — Chuck Yeager franchit le mur du son."],
        "10-21": ["1805 — Bataille de Trafalgar."],
        "10-31": ["1517 — Luther publie ses 95 thèses à Wittemberg."],
        "11-09": ["1989 — Chute du mur de Berlin."],
        "11-11": ["1918 — Armistice de Rethondes, fin de la Grande Guerre."],
        "11-18": ["1928 — Première apparition de Mickey Mouse à l’écran."],
        "11-22": ["1963 — Assassinat de John F. Kennedy à Dallas."],
        "12-01": ["1955 — Rosa Parks refuse de céder sa place dans un bus de Montgomery."],
        "12-10": ["1948 — Adoption de la Déclaration universelle des droits de l’homme."],
        "12-17": ["1903 — Premier vol motorisé des frères Wright."],
        "12-21": ["1968 — Apollo 8 quitte l’orbite terrestre vers la Lune."],
        "12-25": ["800 — Charlemagne est couronné empereur à Rome."],
        "12-28": ["1895 — Première projection publique payante des frères Lumière."],
        "12-31": ["1999 — Passage à l’an 2000, redouté pour le « bug » informatique."]
    ]
}
