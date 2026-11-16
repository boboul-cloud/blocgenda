import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case roll, journal, day, agenda, directory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .roll: return "Rouleau"
        case .journal: return "Journal"
        case .day: return "Le jour"
        case .agenda: return "Agenda"
        case .directory: return "Annuaire"
        }
    }

    var icon: String {
        switch self {
        case .roll: return "scroll"
        case .journal: return "book.closed"
        case .day: return "sun.horizon"
        case .agenda: return "calendar"
        case .directory: return "person.text.rectangle"
        }
    }

    /// Lien profond associé à l'onglet : `blocgenda://jour`, etc.
    /// Utilisé par les widgets et par Raccourcis.
    var url: URL? { URL(string: "blocgenda://\(deepLink)") }

    var deepLink: String {
        switch self {
        case .roll: return "rouleau"
        case .journal: return "journal"
        case .day: return "jour"
        case .agenda: return "agenda"
        case .directory: return "annuaire"
        }
    }

    init?(deepLink: String) {
        guard let match = Tab.allCases.first(where: { $0.deepLink == deepLink }) else { return nil }
        self = match
    }

    var iconFilled: String {
        switch self {
        case .roll: return "scroll.fill"
        case .journal: return "book.closed.fill"
        case .day: return "sun.horizon.fill"
        case .agenda: return "calendar"
        case .directory: return "person.text.rectangle.fill"
        }
    }
}

struct RootView: View {
    @Environment(Store.self) private var store
    @State private var nav = Navigator()
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Ink.chassis.ignoresSafeArea()

            Group {
                switch nav.tab {
                case .roll: RollView()
                case .journal: JournalView()
                case .day: TodayView()
                case .agenda: AgendaView()
                case .directory: DirectoryView()
                }
            }
            .transition(.opacity)

            TabBar(selection: $nav.tab, onSettings: { showSettings = true })
        }
        .environment(nav)
        .animation(.snappy(duration: 0.22), value: nav.tab)
        .onOpenURL { url in
            // blocgenda://jour — ouvert par les widgets et par Raccourcis.
            guard url.scheme == "blocgenda" else { return }
            let target = url.host() ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if target == "reglages" {
                showSettings = true
            } else if let destination = Tab(deepLink: target) {
                nav.tab = destination
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(store)
        }
    }
}

/// Barre d'onglets flottante : un bandeau d'ivoire posé sur le châssis.
/// L'onglet ouvert est signalé deux fois — par la couleur *et* par la pastille
/// qui le porte : la couleur seule ne suffit pas à qui la distingue mal.
struct TabBar: View {
    @Binding var selection: Tab
    var onSettings: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Tab.allCases) { tab in
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    selection = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: selection == tab ? tab.iconFilled : tab.icon)
                            .font(Type.icon(17, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                        Text(tab.title)
                            .font(Type.ui(8.5, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selection == tab ? Ink.amberDeep : Ink.textSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selection == tab ? Ink.amber.opacity(0.16) : .clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("onglet.\(tab.rawValue)")
                .accessibilityLabel(tab.title)
            }

            Rectangle()
                .fill(Ink.chassisLine)
                .frame(width: 1, height: 26)
                .padding(.horizontal, 4)

            Button(action: onSettings) {
                Image(systemName: "slider.horizontal.3")
                    .font(Type.icon(16, weight: .semibold))
                    .foregroundStyle(Ink.textSoft)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Réglages")
        }
        .padding(.horizontal, 6)
        .background(
            Capsule()
                .fill(Ink.chassisSoft)
                .overlay(Capsule().strokeBorder(Ink.chassisLine, lineWidth: 1))
                .shadow(color: Ink.text.opacity(0.14), radius: 16, y: 6)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

/// En-tête commun : titre en gros, sous-titre discret, accessoire à droite.
struct ScreenHeader<Accessory: View>: View {
    var title: String
    var subtitle: String?
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Type.display)
                    .foregroundStyle(Ink.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle {
                    Text(subtitle)
                        .font(Type.ui(13, weight: .medium))
                        .foregroundStyle(Ink.textSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            Spacer(minLength: 8)
            accessory
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

extension ScreenHeader where Accessory == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}
