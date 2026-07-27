//
//  GameViewModel.swift
//  DemonicEleven
//

import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    enum Turn {
        case player
        case computer
    }

    enum Winner {
        case player
        case computer
    }

    struct LogEntry: Identifiable {
        enum Kind {
            case player
            case computer
            case system
        }

        let id = UUID()
        let text: String
        let kind: Kind
    }

    @Published private(set) var total = 0
    @Published private(set) var turn: Turn = .player
    @Published private(set) var winner: Winner?
    @Published private(set) var log: [LogEntry] = []
    @Published private(set) var isComputerThinking = false

    private let target = 100

    // Werte, die nach einem Zug erreicht werden sollten (100 minus Vielfache von 11),
    // um mit perfektem Spiel garantiert zu gewinnen.
    private let winningPositions = [1, 12, 23, 34, 45, 56, 67, 78, 89, 100]

    var maxSelectable: Int { min(10, target - total) }

    init() {
        startNewGame()
    }

    func startNewGame() {
        total = 0
        winner = nil
        log = []
        isComputerThinking = false
        turn = Bool.random() ? .player : .computer
        log.append(LogEntry(
            text: turn == .player ? "Neues Spiel! Du beginnst." : "Neues Spiel! Der Computer beginnt.",
            kind: .system
        ))
        if turn == .computer {
            performComputerTurn()
        }
    }

    func playerSelected(_ value: Int) {
        guard turn == .player, winner == nil, value >= 1, value <= maxSelectable else { return }
        applyMove(value: value, kind: .player)
        guard winner == nil else { return }
        turn = .computer
        performComputerTurn()
    }

    private func performComputerTurn() {
        isComputerThinking = true
        let thinkingDelay = Double.random(in: 0.6...1.3)
        Task {
            try? await Task.sleep(for: .seconds(thinkingDelay))
            guard winner == nil else { return }
            let value = computerMove()
            isComputerThinking = false
            applyMove(value: value, kind: .computer)
            if winner == nil {
                turn = .player
            }
        }
    }

    private func computerMove() -> Int {
        let maxVal = maxSelectable
        guard maxVal >= 1 else { return 0 }

        // Der Computer spielt meist optimal, verpasst den perfekten Zug aber
        // gelegentlich absichtlich, damit das Spiel für Menschen schlagbar bleibt.
        if Double.random(in: 0...1) < 0.8,
           let bestTarget = winningPositions.first(where: { $0 > total && $0 - total <= maxVal }) {
            return bestTarget - total
        }
        return Int.random(in: 1...maxVal)
    }

    private func applyMove(value: Int, kind: LogEntry.Kind) {
        let from = total
        total += value
        let prefix = kind == .player ? "Du hast" : "Computer hat"
        log.append(LogEntry(text: "\(prefix) \(value) hinzugefügt! \(from) -> \(total)", kind: kind))

        if total == target {
            winner = kind == .player ? .player : .computer
            let resultText = winner == .player ? "🎉 Du hast gewonnen!" : "💀 Der Computer hat gewonnen!"
            log.append(LogEntry(text: resultText, kind: .system))
        }
    }
}
