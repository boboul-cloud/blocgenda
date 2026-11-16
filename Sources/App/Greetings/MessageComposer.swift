import MessageUI
import SwiftUI

/// Le composeur de Messages d'iOS, présenté tel quel.
///
/// C'est le seul chemin qui garantisse le destinataire **et** le texte déjà
/// écrits — un lien `sms:` prend le corps du message selon la version d'iOS —
/// et il laisse le dernier mot où il doit être : c'est l'utilisateur qui appuie
/// sur envoyer, jamais l'application.
struct MessageComposer: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    var onFinish: (MessageComposeResult) -> Void

    /// Faux sur un appareil sans SMS — le simulateur, un iPad sans carte SIM.
    /// L'appelant se rabat alors sur un lien `sms:`.
    static var isAvailable: Bool { MFMessageComposeViewController.canSendText() }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.recipients = recipients
        composer.body = body
        composer.messageComposeDelegate = context.coordinator
        return composer
    }

    func updateUIViewController(_ composer: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        private let onFinish: (MessageComposeResult) -> Void

        init(onFinish: @escaping (MessageComposeResult) -> Void) {
            self.onFinish = onFinish
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            onFinish(result)
        }
    }
}
