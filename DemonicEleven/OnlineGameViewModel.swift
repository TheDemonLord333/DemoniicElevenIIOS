//
//  OnlineGameViewModel.swift
//  DemonicEleven
//
//  Mehrspieler-Modus: verbindet sich per WebSocket mit dem Backend
//  (Backend/README.md), das zwei Spieler matcht und Zuege validiert.
//  Benoetigt eine Internetverbindung.
//

import Foundation
import Combine

@MainActor
final class OnlineGameViewModel: GameEngine {

    private enum Phase {
        case connecting
        case searching
        case playing
        case finished(String)
        case failed(String)
    }

    @Published private(set) var total = 0
    @Published private(set) var log: [GameLogEntry] = []
    @Published private(set) var isMyTurn = false
    @Published private var phase: Phase = .connecting

    private let serverURL: URL
    private var task: URLSessionWebSocketTask?
    private var connectionID = UUID()

    init(serverURL: URL = URL(string: "wss://d11.thedemonlord333.me")!) {
        self.serverURL = serverURL
        connect()
    }

    var maxSelectable: Int { min(10, 100 - total) }

    var canAct: Bool {
        if case .playing = phase { return isMyTurn }
        return false
    }

    var statusText: String {
        switch phase {
        case .connecting: return "Verbinde mit Server..."
        case .searching: return "Suche Gegner..."
        case .playing: return isMyTurn ? "Du bist dran" : "Gegner ist am Zug"
        case .finished, .failed: return ""
        }
    }

    var statusKind: GameStatusKind {
        switch phase {
        case .connecting, .searching: return .waiting
        case .playing: return isMyTurn ? .me : .opponent
        case .failed: return .error
        case .finished: return .me
        }
    }

    var resultText: String? {
        switch phase {
        case .finished(let text), .failed(let text): return text
        case .connecting, .searching, .playing: return nil
        }
    }

    var restartLabel: String {
        if case .failed = phase { return "Erneut verbinden" }
        return "Neues Spiel"
    }

    func selectValue(_ value: Int) {
        guard canAct, value >= 1, value <= maxSelectable else { return }
        send(["type": "move", "value": value])
    }

    func restart() {
        task?.cancel(with: .goingAway, reason: nil)
        total = 0
        log = []
        isMyTurn = false
        phase = .connecting
        connect()
    }

    private func connect() {
        let id = UUID()
        connectionID = id

        let newTask = URLSession(configuration: .default).webSocketTask(with: serverURL)
        task = newTask
        newTask.resume()
        listen(id: id)
    }

    private func listen(id: UUID) {
        task?.receive { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                guard self.connectionID == id else { return }

                switch result {
                case .failure:
                    if case .finished = self.phase {
                        // Sieg/Niederlage wurde bereits angezeigt, ein nachfolgender
                        // Verbindungsabbruch soll den Bildschirm nicht mehr ueberschreiben.
                    } else {
                        self.phase = .failed("⚠️ Verbindung zum Server verloren")
                    }

                case .success(let message):
                    if case .string(let text) = message, let data = text.data(using: .utf8) {
                        self.handle(data: data)
                    }
                    self.listen(id: id)
                }
            }
        }
    }

    private func handle(data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "welcome":
            phase = .searching
            send(["type": "join"])

        case "queued":
            phase = .searching

        case "matchFound":
            total = 0
            log = [GameLogEntry(text: "Gegner gefunden! Das Spiel beginnt.", kind: .system)]
            isMyTurn = json["yourTurn"] as? Bool ?? false
            phase = .playing

        case "move":
            guard let value = json["value"] as? Int,
                  let from = json["from"] as? Int,
                  let to = json["to"] as? Int,
                  let isYou = json["isYou"] as? Bool else { return }
            let prefix = isYou ? "Du hast" : "Gegner hat"
            log.append(GameLogEntry(
                text: "\(prefix) \(value) hinzugefügt! \(from) -> \(to)",
                kind: isYou ? .me : .opponent
            ))
            total = to

        case "state":
            if let currentTotal = json["total"] as? Int { total = currentTotal }
            isMyTurn = json["yourTurn"] as? Bool ?? false
            if let winner = json["winner"] as? String {
                phase = .finished(winner == "you" ? "🎉 Du hast gewonnen!" : "💀 Der Gegner hat gewonnen!")
            }

        case "opponentLeft":
            phase = .finished("🚪 Der Gegner hat das Spiel verlassen.")

        case "error":
            let reason = json["message"] as? String ?? "unbekannter Fehler"
            phase = .failed("⚠️ Serverfehler: \(reason)")

        default:
            break
        }
    }

    private func send(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return }
        task?.send(.string(text)) { _ in }
    }
}
