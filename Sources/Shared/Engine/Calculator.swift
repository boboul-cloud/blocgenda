import Foundation

/// Évaluateur d'expressions arithmétiques « à la française » :
/// virgule décimale, espaces comme séparateurs de milliers, × ÷ acceptés,
/// pourcentages à la manière d'une calculatrice de bureau.
///
///     "12,50 × 3"        → 37,5
///     "200 + 10%"        → 220        (10 % de 200 ajoutés)
///     "20% de 80"        → 16
///     "1 250 € - 199,99" → 1050,01
enum Calculator {

    struct Result: Hashable, Sendable {
        var value: Double
        /// Expression ré-imprimée proprement pour la bande.
        var pretty: String
    }

    enum CalcError: Error { case invalid }

    /// Renvoie nil si la chaîne n'est pas (entièrement) une expression de calcul.
    static func evaluate(_ raw: String) -> Result? {
        let cleaned = normalize(raw)
        guard !cleaned.isEmpty else { return nil }
        guard cleaned.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789")) != nil else { return nil }
        // Une expression doit contenir au moins un opérateur ou une parenthèse,
        // sinon un simple nombre serait interprété comme un calcul.
        var tokens: [Token]
        do { tokens = try tokenize(cleaned) } catch { return nil }
        let hasOperator = tokens.contains {
            switch $0 {
            case .op, .percent, .function: return true
            default: return false
            }
        }
        guard hasOperator else { return nil }

        var parser = Parser(tokens: tokens)
        guard let value = try? parser.parseExpression(), parser.isAtEnd, value.isFinite else { return nil }
        return Result(value: value, pretty: prettify(cleaned))
    }

    /// Version tolérante : évalue même un nombre seul (utilisée par le clavier).
    static func evaluateLoose(_ raw: String) -> Double? {
        let cleaned = normalize(raw)
        guard !cleaned.isEmpty else { return nil }
        guard var tokens = try? tokenize(cleaned) else { return nil }
        // Ferme les parenthèses laissées ouvertes par le clavier.
        let opened = tokens.filter { if case .lparen = $0 { return true } else { return false } }.count
        let closed = tokens.filter { if case .rparen = $0 { return true } else { return false } }.count
        if opened > closed { tokens.append(contentsOf: Array(repeating: Token.rparen, count: opened - closed)) }
        // Ignore un opérateur final ("12 +").
        if case .op = tokens.last { tokens.removeLast() }
        var parser = Parser(tokens: tokens)
        guard let value = try? parser.parseExpression(), value.isFinite else { return nil }
        return value
    }

    // MARK: - Normalisation

    static func normalize(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "\u{00A0}", with: " ")
        s = s.replacingOccurrences(of: "\u{202F}", with: " ")
        for symbol in ["€", "$", "£", "CHF", "eur", "EUR", "euros", "euro"] {
            s = s.replacingOccurrences(of: symbol, with: " ")
        }
        s = s.replacingOccurrences(of: "×", with: "*")
        s = s.replacingOccurrences(of: "÷", with: "/")
        s = s.replacingOccurrences(of: "−", with: "-")
        s = s.replacingOccurrences(of: "–", with: "-")
        s = s.replacingOccurrences(of: ",", with: ".")
        // « 20% de 80 » ou « 20 % sur 80 » → 20% * 80
        s = s.replacingOccurrences(of: " de ", with: " * ", options: [.caseInsensitive])
        s = s.replacingOccurrences(of: " sur ", with: " * ", options: [.caseInsensitive])
        s = s.replacingOccurrences(of: " fois ", with: " * ", options: [.caseInsensitive])
        s = s.replacingOccurrences(of: " plus ", with: " + ", options: [.caseInsensitive])
        s = s.replacingOccurrences(of: " moins ", with: " - ", options: [.caseInsensitive])
        // « x » utilisé comme multiplication entre deux chiffres
        s = s.replacingOccurrences(of: #"(?<=\d)\s*[xX]\s*(?=\d)"#, with: "*", options: .regularExpression)
        // Espaces de milliers : « 1 250 » → « 1250 »
        s = s.replacingOccurrences(of: #"(?<=\d) +(?=\d{3}\b)"#, with: "", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespaces)
    }

    static func prettify(_ normalized: String) -> String {
        var s = normalized
        s = s.replacingOccurrences(of: "*", with: " × ")
        s = s.replacingOccurrences(of: "/", with: " ÷ ")
        s = s.replacingOccurrences(of: "+", with: " + ")
        s = s.replacingOccurrences(of: #"(?<=[\d\)%])-"#, with: " - ", options: .regularExpression)
        s = s.replacingOccurrences(of: ".", with: ",")
        // Typographie française : une espace insécable avant le pour-cent.
        s = s.replacingOccurrences(of: #"\s*%"#, with: "\u{00A0}%", options: .regularExpression)
        s = s.replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Analyse lexicale

    enum Token: Hashable {
        case number(Double)
        case op(Character)
        case lparen
        case rparen
        case percent
        case function(String)
    }

    static func tokenize(_ s: String) throws -> [Token] {
        var tokens: [Token] = []
        let chars = Array(s)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == " " { i += 1; continue }
            if c.isNumber || c == "." {
                var literal = ""
                while i < chars.count, chars[i].isNumber || chars[i] == "." {
                    literal.append(chars[i]); i += 1
                }
                guard let value = Double(literal) else { throw CalcError.invalid }
                tokens.append(.number(value))
                continue
            }
            if c.isLetter {
                var word = ""
                while i < chars.count, chars[i].isLetter { word.append(chars[i]); i += 1 }
                let key = word.lowercased().folding(options: .diacriticInsensitive, locale: .current)
                guard ["racine", "sqrt", "abs", "arrondi", "round", "min", "max"].contains(key) else {
                    throw CalcError.invalid
                }
                tokens.append(.function(key))
                continue
            }
            switch c {
            case "+", "-", "*", "/", "^": tokens.append(.op(c))
            case "(": tokens.append(.lparen)
            case ")": tokens.append(.rparen)
            case "%": tokens.append(.percent)
            case ";", ",": tokens.append(.op(";"))
            default: throw CalcError.invalid
            }
            i += 1
        }
        return tokens
    }

    // MARK: - Analyse syntaxique (descente récursive)

    struct Parser {
        let tokens: [Token]
        var index = 0

        init(tokens: [Token]) { self.tokens = tokens }

        var isAtEnd: Bool { index >= tokens.count }
        var peek: Token? { index < tokens.count ? tokens[index] : nil }

        mutating func parseExpression() throws -> Double {
            var left = try parseTerm()
            while case .op(let c)? = peek, c == "+" || c == "-" {
                index += 1
                let right = try parseTermForAddition(base: left, isAddition: c == "+")
                left = c == "+" ? left + right : left - right
            }
            return left
        }

        /// Gère la sémantique « 200 + 10 % » = 200 + 10 % de 200.
        mutating func parseTermForAddition(base: Double, isAddition: Bool) throws -> Double {
            let start = index
            let value = try parseTerm()
            // Si le terme consommé était un pourcentage nu, il porte sur la base.
            if wasBarePercent(from: start) { return base * value }
            return value
        }

        func wasBarePercent(from start: Int) -> Bool {
            let slice = tokens[start..<index]
            guard slice.count == 2 else { return false }
            if case .number = slice.first, case .percent = slice.last { return true }
            return false
        }

        mutating func parseTerm() throws -> Double {
            var left = try parseFactor()
            while case .op(let c)? = peek, c == "*" || c == "/" {
                index += 1
                let right = try parseFactor()
                if c == "*" { left *= right } else {
                    guard right != 0 else { throw CalcError.invalid }
                    left /= right
                }
            }
            return left
        }

        mutating func parseFactor() throws -> Double {
            var base = try parseUnary()
            if case .op(let c)? = peek, c == "^" {
                index += 1
                let exponent = try parseFactor()
                base = pow(base, exponent)
            }
            return base
        }

        mutating func parseUnary() throws -> Double {
            if case .op(let c)? = peek, c == "-" {
                index += 1
                return try -parseUnary()
            }
            if case .op(let c)? = peek, c == "+" {
                index += 1
                return try parseUnary()
            }
            return try parsePostfix()
        }

        mutating func parsePostfix() throws -> Double {
            var value = try parsePrimary()
            while case .percent? = peek {
                index += 1
                value /= 100
            }
            return value
        }

        mutating func parsePrimary() throws -> Double {
            switch peek {
            case .number(let v):
                index += 1
                return v
            case .lparen:
                index += 1
                let v = try parseExpression()
                guard case .rparen? = peek else { throw CalcError.invalid }
                index += 1
                return v
            case .function(let name):
                index += 1
                guard case .lparen? = peek else {
                    // « racine 16 » sans parenthèses
                    let arg = try parseUnary()
                    return try apply(name, [arg])
                }
                index += 1
                var args: [Double] = [try parseExpression()]
                while case .op(let c)? = peek, c == ";" {
                    index += 1
                    args.append(try parseExpression())
                }
                guard case .rparen? = peek else { throw CalcError.invalid }
                index += 1
                return try apply(name, args)
            default:
                throw CalcError.invalid
            }
        }

        func apply(_ name: String, _ args: [Double]) throws -> Double {
            switch name {
            case "racine", "sqrt":
                guard let a = args.first, a >= 0 else { throw CalcError.invalid }
                return sqrt(a)
            case "abs":
                guard let a = args.first else { throw CalcError.invalid }
                return Swift.abs(a)
            case "arrondi", "round":
                guard let a = args.first else { throw CalcError.invalid }
                let digits = args.count > 1 ? args[1] : 0
                let f = pow(10, digits)
                return (a * f).rounded() / f
            case "min":
                guard let m = args.min() else { throw CalcError.invalid }
                return m
            case "max":
                guard let m = args.max() else { throw CalcError.invalid }
                return m
            default: throw CalcError.invalid
            }
        }
    }
}

// MARK: - Formatage

enum NumberStyleFR {
    static let plain: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.numberStyle = .decimal
        f.maximumFractionDigits = 6
        f.minimumFractionDigits = 0
        f.usesGroupingSeparator = true
        return f
    }()

    static let money: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        f.usesGroupingSeparator = true
        return f
    }()

    static func format(_ value: Double) -> String {
        plain.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func money(_ value: Double, symbol: String = "€") -> String {
        let s = money.string(from: NSNumber(value: value)) ?? String(value)
        return symbol.isEmpty ? s : "\(s) \(symbol)"
    }
}
