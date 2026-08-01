//
//  GameBoardView.swift
//  DemonicEleven
//
//  Gemeinsame Spielansicht fuer Einzelspieler (GameViewModel) und
//  Mehrspieler (OnlineGameViewModel) - beide erfuellen das GameEngine-Protokoll.
//

import SwiftUI

struct GameBoardView<Engine: GameEngine>: View {
    @ObservedObject var engine: Engine
    let title: String

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 16) {
                totalDisplay
                statusView
                logView
                Spacer(minLength: 0)
                numberPad
            }
            .padding()

            if let resultText = engine.resultText {
                resultOverlay(resultText)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.09, green: 0.03, blue: 0.16)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var totalDisplay: some View {
        VStack(spacing: 8) {
            Text("\(engine.total)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .green], startPoint: .leading, endPoint: .trailing)
                )
                .contentTransition(.numericText())
                .animation(.snappy, value: engine.total)

            ProgressView(value: Double(engine.total), total: 100)
                .tint(.purple)
        }
    }

    private var statusView: some View {
        Group {
            if engine.resultText == nil {
                HStack(spacing: 8) {
                    if engine.statusKind == .waiting {
                        ProgressView().tint(statusColor)
                    } else if engine.statusKind == .error {
                        Image(systemName: "wifi.exclamationmark")
                    }
                    Text(engine.statusText)
                }
                .font(.subheadline.bold())
                .foregroundStyle(statusColor)
            }
        }
    }

    private var statusColor: Color {
        switch engine.statusKind {
        case .me: return .green
        case .opponent: return .purple
        case .waiting: return .white.opacity(0.7)
        case .error: return .red
        }
    }

    private var logView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(engine.log) { entry in
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
            .onChange(of: engine.log.count) { _, _ in
                guard let last = engine.log.last else { return }
                withAnimation {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private func color(for kind: GameLogEntry.Kind) -> Color {
        switch kind {
        case .me: return .green
        case .opponent: return .purple
        case .system: return .white.opacity(0.7)
        }
    }

    private var numberPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
            ForEach(1...10, id: \.self) { value in
                Button {
                    engine.selectValue(value)
                } label: {
                    Text("\(value)")
                }
                .buttonStyle(DemonicNumberButtonStyle())
                .disabled(!engine.canAct || value > engine.maxSelectable)
            }
        }
    }

    private func resultOverlay(_ text: String) -> some View {
        VStack(spacing: 20) {
            Text(text)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Button(engine.restartLabel) {
                engine.restart()
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
struct DemonicNumberButtonStyle: ButtonStyle {
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
    NavigationStack {
        GameBoardView(engine: GameViewModel(), title: "Einzelspieler")
    }
    .preferredColorScheme(.dark)
}
