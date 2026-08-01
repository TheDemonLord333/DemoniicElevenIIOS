//
//  ContentView.swift
//  DemonicEleven
//
//  Created by David Martens on 27.07.26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameViewModel()

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 16) {
                header
                totalDisplay
                turnIndicator
                logView
                Spacer(minLength: 0)
                numberPad
            }
            .padding()

            if let winner = game.winner {
                winnerOverlay(winner)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.09, green: 0.03, blue: 0.16)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image("GameLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("DEMONIC ELEVEN")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Zähl bis genau 100")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
    }

    private var totalDisplay: some View {
        VStack(spacing: 8) {
            Text("\(game.total)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .green], startPoint: .leading, endPoint: .trailing)
                )
                .contentTransition(.numericText())
                .animation(.snappy, value: game.total)

            ProgressView(value: Double(game.total), total: 100)
                .tint(.purple)
        }
    }

    private var turnIndicator: some View {
        Group {
            if game.winner != nil {
                EmptyView()
            } else if game.turn == .player {
                Label("Du bist dran", systemImage: "person.fill")
                    .foregroundStyle(.green)
            } else {
                Label(
                    game.isComputerThinking ? "Computer denkt nach..." : "Computer ist dran",
                    systemImage: "cpu"
                )
                .foregroundStyle(.purple)
            }
        }
        .font(.subheadline.bold())
    }

    private var logView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(game.log) { entry in
                        Text(entry.text)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(color(for: entry.kind))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(entry.id)
                    }
                }
                .padding(10)
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .frame(maxHeight: 220)
            .onChange(of: game.log.count) { _, _ in
                guard let last = game.log.last else { return }
                withAnimation {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private func color(for kind: GameViewModel.LogEntry.Kind) -> Color {
        switch kind {
        case .player: return .green
        case .computer: return .purple
        case .system: return .white.opacity(0.7)
        }
    }

    private var numberPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
            ForEach(1...10, id: \.self) { value in
                Button {
                    game.playerSelected(value)
                } label: {
                    Text("\(value)")
                }
                .buttonStyle(DemonicNumberButtonStyle())
                .disabled(game.turn != .player || game.winner != nil || value > game.maxSelectable)
            }
        }
    }

    private func winnerOverlay(_ winner: GameViewModel.Winner) -> some View {
        VStack(spacing: 20) {
            Text(winner == .player ? "🎉 Du hast gewonnen!" : "💀 Der Computer hat gewonnen!")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Button("Neues Spiel") {
                game.startNewGame()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(40)
    }
}

/// Zahlen-Knöpfe im Look des App-Icons: dunkler Steinsockel, lila/grüner
/// Flammen-Rahmen und ein leichtes Glühen, das beim Drücken zusammenfällt.
private struct DemonicNumberButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let glowColors: [Color] = isEnabled ? [.purple, .green] : [.gray.opacity(0.35), .gray.opacity(0.25)]

        configuration.label
            .font(.system(.title3, design: .rounded).weight(.heavy))
            .foregroundStyle(
                isEnabled
                    ? AnyShapeStyle(LinearGradient(colors: [.white, .green], startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Color.white.opacity(0.3))
            )
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [Color(red: 0.1, green: 0.03, blue: 0.16), Color.black]
                                : [Color(white: 0.09), Color(white: 0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: glowColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: isEnabled ? .purple.opacity(0.55) : .clear, radius: configuration.isPressed ? 2 : 7)
            .shadow(color: isEnabled ? .green.opacity(0.4) : .clear, radius: configuration.isPressed ? 1 : 4)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
