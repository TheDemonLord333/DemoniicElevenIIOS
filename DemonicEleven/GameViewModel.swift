//
//  GameViewModel.swift
//  DemonicEleven
//
//  Einzelspieler-Modus: lokales Spiel gegen eine simple KI, keine Internetverbindung nötig.
//

import Foundation
import Combine

@MainActor
final class GameViewModel: GameEngine {
    @Published private(set) var total = 0
    @Published private(set) var log: [GameLogEntry] = []
    @Published private(set) var resultText: String?
    @Published private(set) var isPlayerTurn = true
    @Published private(set) var isComputerThinking = false

    private let target = 100

    // Werte, die nach einem Zug erreicht werden sollten (100 minus Vielfache von 11),
    // um mit perfektem Spiel garantiert zu gewinnen.
    private let winningPositions = [1, 12, 23, 34, 45, 56, 67, 78, 89, 100]

    var maxSelectable: Int { min(10, target - total) }
    var canAct: Bool { isPlayerTurn && resultText == nil }

    var statusText: String {
        if resultText != nil { return "" }
        if isPlayerTurn { return "Du bist dran" }
        return isComputerThinking ? "Computer denkt nach..." : "Computer ist dran"
    }

    var statusKind: GameStatusKind { isPlayerTurn ? .me : .opponent }

    init() {
        restart()
    }

    func restart() {
        total = 0
        resultText = nil
        log = []
        isComputerThinking = false
        isPlayerTurn = Bool.random()
        log.append(GameLogEntry(
            text: isPlayerTurn ? "Neues Spiel! Du beginnst." : "Neues Spiel! Der Computer beginnt.",
            kind: .system
        ))
        if !isPlayerTurn {
            performComputerTurn()
        }
    }

    func selectValue(_ value: Int) {
        guard isPlayerTurn, resultText == nil, value >= 1, value <= maxSelectable else { return }
        applyMove(value: value, kind: .me)
        guard resultText == nil else { return }
        isPlayerTurn = false
        performComputerTurn()
    }

    private func performComputerTurn() {
        isComputerThinking = true
        let thinkingDelay = Double.random(in: 0.6...1.3)
        Task {
            try? await Task.sleep(for: .seconds(thinkingDelay))
            guard resultText == nil else { return }
            let value = computerMove()
            isComputerThinking = false
            applyMove(value: value, kind: .opponent)
            if resultText == nil {
                isPlayerTurn = true
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

    private func applyMove(value: Int, kind: GameLogEntry.Kind) {
        let from = total
        total += value
        let prefix = kind == .me ? "Du hast" : "Computer hat"
        log.append(GameLogEntry(text: "\(prefix) \(value) hinzugefügt! \(from) -> \(total)", kind: kind))

        if total == target {
            resultText = kind == .me ? "🎉 Du hast gewonnen!" : "💀 Der Computer hat gewonnen!"
        }
    }
}
