//
//  GameModels.swift
//  DemonicEleven
//

import Foundation

struct GameLogEntry: Identifiable {
    enum Kind: Equatable {
        case me
        case opponent
        case system
    }

    let id = UUID()
    let text: String
    let kind: Kind
}

enum GameStatusKind: Equatable {
    case me
    case opponent
    case waiting
    case error
}

/// Gemeinsame Schnittstelle für Einzelspieler (lokale KI) und Mehrspieler
/// (Online-Verbindung), damit beide dieselbe Spielansicht (GameBoardView) nutzen können.
@MainActor
protocol GameEngine: ObservableObject {
    var total: Int { get }
    var log: [GameLogEntry] { get }
    var maxSelectable: Int { get }
    var canAct: Bool { get }
    var statusText: String { get }
    var statusKind: GameStatusKind { get }
    var resultText: String? { get }
    var restartLabel: String { get }

    func selectValue(_ value: Int)
    func restart()
}

extension GameEngine {
    var restartLabel: String { "Neues Spiel" }
}
