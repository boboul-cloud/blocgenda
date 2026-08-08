import SwiftUI

/// Le clavier de la machine à calculer. Il écrit dans la même barre que le
/// texte : un calcul reste une phrase que l'on peut relire et corriger.
struct Keypad: View {
    @Binding var text: String
    var onEqual: () -> Void
    var onTotal: () -> Void
    @Environment(Store.self) private var store

    private enum Key: Hashable {
        case digit(String)
        case op(String)
        case clear, back, equal, total, vat, percent
    }

    private let rows: [[Key]] = [
        [.clear, .op("("), .op(")"), .percent],
        [.digit("7"), .digit("8"), .digit("9"), .op(" ÷ ")],
        [.digit("4"), .digit("5"), .digit("6"), .op(" × ")],
        [.digit("1"), .digit("2"), .digit("3"), .op(" − ")],
        [.digit("0"), .digit(","), .back, .op(" + ")]
    ]

    var body: some View {
        VStack(spacing: 7) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 7) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, key in
                        button(key)
                    }
                }
            }
            HStack(spacing: 7) {
                button(.vat, wide: false)
                button(.total, wide: false)
                button(.equal, wide: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func button(_ key: Key, wide: Bool = false) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            apply(key)
        } label: {
            Group {
                if let symbol = symbolName(key) {
                    Image(systemName: symbol)
                        .font(Type.icon(17, weight: .semibold))
                } else {
                    Text(title(key))
                        .font(Type.tape(19, weight: .medium))
                }
            }
            .foregroundStyle(foreground(key))
            .frame(maxWidth: .infinity)
            .frame(height: Type.control(46))
            .frame(width: wide ? nil : nil)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(background(key))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Ink.chassisLine, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: wide ? .infinity : nil)
    }

    private func title(_ key: Key) -> String {
        switch key {
        case .digit(let d): return d
        case .op(let o): return o.trimmingCharacters(in: .whitespaces)
        case .clear: return "C"
        case .equal: return "="
        case .total: return "TOT"
        case .vat: return "TVA"
        case .percent: return "%"
        case .back: return "⌫"
        }
    }

    private func symbolName(_ key: Key) -> String? {
        if case .back = key { return "delete.left" }
        return nil
    }

    private func foreground(_ key: Key) -> Color {
        switch key {
        case .digit: return Ink.text
        case .op, .percent: return Ink.amberDeep
        case .clear: return Ink.rouge
        case .equal: return Ink.onAccent
        case .total, .vat: return Ink.sea
        case .back: return Ink.textSoft
        }
    }

    private func background(_ key: Key) -> Color {
        switch key {
        case .equal: return Ink.amber
        case .digit: return Ink.chassisSoft
        default: return Ink.sunken
        }
    }

    private func apply(_ key: Key) {
        switch key {
        case .digit(let d): text += d
        case .op(let o): text += o
        case .percent: text += " %"
        case .clear: text = ""
        case .back: if !text.isEmpty { text.removeLast() }
        case .vat:
            let factor = 1 + store.settings.vatRate / 100
            text += " × \(NumberStyleFR.format(factor))"
        case .total:
            onTotal()
            text = ""
        case .equal:
            onEqual()
        }
    }
}
