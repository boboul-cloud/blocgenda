import AppIntents
import Foundation
import WidgetKit

/// Cocher une action directement depuis le widget, sans ouvrir l'app.
/// L'intention écrit dans le même fichier partagé que l'application.
struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Cocher l’action"
    static var description = IntentDescription("Marque comme faite la première action du jour.")

    @Parameter(title: "Identifiant")
    var entryID: String

    init() { entryID = "" }
    init(entryID: String) { self.entryID = entryID }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: entryID),
              var tape = SharedStorage.load([TapeEntry].self, from: .tape),
              let index = tape.firstIndex(where: { $0.id == uuid }) else {
            return .result()
        }
        tape[index].done.toggle()
        SharedStorage.save(tape, to: .tape)

        // On rafraîchit la photographie pour que le widget montre l'action suivante.
        var snapshot = WidgetSnapshot.load()
        let today = Calendar.current.startOfDay(for: Date())
        let todayTasks = tape.filter {
            $0.isOnRoll && $0.kind == .task && Calendar.current.startOfDay(for: $0.date) == today
        }
        snapshot.openTaskCount = todayTasks.filter { !$0.done }.count
        snapshot.doneTaskCount = todayTasks.filter(\.done).count
        let next = todayTasks.first { !$0.done }
        snapshot.firstOpenTask = next?.text
        snapshot.firstOpenTaskID = next?.id.uuidString
        snapshot.save()

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
