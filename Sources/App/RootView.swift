import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case roll, day, agenda, directory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .roll: return "Rouleau"
        case .day: return "Le jour"
        case .agenda: return "Agenda"
        case .directory: return "Annuaire"
        }
    }

    var icon: String {
        switch self {
        case .roll: return "scroll"
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
        case .day: return "sun.horizon.fill"
        case .agenda: return "calendar"
        case .directory: return "person.text.rectangle.fill"
        }
    }
}

struct RootView: View {
    @Environment(Store.self) private var store
    @State private var tab: Tab = .roll
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Ink.chassis.ignoresSafeArea()

            Group {
                switch tab {
                case .roll: RollView()
                case .day: TodayView()
                case .agenda: AgendaView()
                case .directory: DirectoryView()
                }
            }
            .transition(.opacity)

            TabBar(selection: $tab, onSettings: { showSettings = true })
        }
        .animation(.snappy(duration: 0.22), value: tab)
        .onOpenURL { url in
            // blocgenda://jour — ouvert par les widgets et par Raccourcis.
            guard url.scheme == "blocgenda" else { return }
            let target = url.host() ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if target == "reglages" {
                showSettings = true
            } else if let destination = Tab(deepLink: target) {
                tab = destination
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(store)
        }
    }
}

/// Barre d'onglets flottante : un bandeau sombre posé sur le châssis.
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
                            .font(.system(size: 17, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                        Text(tab.title)
                            .font(Type.ui(9.5, weight: .semibold))
                    }
                    .foregroundStyle(selection == tab ? Ink.amber : Ink.textFaint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Rectangle()
                .fill(Ink.chassisLine)
                .frame(width: 1, height: 26)
                .padding(.horizontal, 4)

            Button(action: onSettings) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Ink.textFaint)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .background(
            Capsule()
                .fill(Ink.chassisSoft)
                .overlay(Capsule().strokeBorder(Ink.chassisLine, lineWidth: 1))
                .shadow(color: .black.opacity(0.45), radius: 18, y: 8)
        )
        .padding(.horizontal, 14)
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
                    .foregroundStyle(Ink.paper)
                if let subtitle {
                    Text(subtitle)
                        .font(Type.ui(13))
                        .foregroundStyle(Ink.textFaint)
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
