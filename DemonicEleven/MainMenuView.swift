//
//  MainMenuView.swift
//  DemonicEleven
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image("GameLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))

                    Text("DEMONIC ELEVEN")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    Text("Zähl bis genau 100")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                VStack(spacing: 16) {
                    NavigationLink {
                        GameBoardView(engine: GameViewModel(), title: "Einzelspieler")
                    } label: {
                        modeRow(
                            icon: "person.fill",
                            title: "Einzelspieler",
                            subtitle: "Gegen den Computer, offline"
                        )
                    }

                    NavigationLink {
                        GameBoardView(engine: OnlineGameViewModel(), title: "Mehrspieler")
                    } label: {
                        modeRow(
                            icon: "network",
                            title: "Mehrspieler",
                            subtitle: "Online gegen einen anderen Spieler – benötigt Internet"
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.black, Color(red: 0.09, green: 0.03, blue: 0.16)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func modeRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding()
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [.purple, .green], startPoint: .leading, endPoint: .trailing),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    NavigationStack {
        MainMenuView()
    }
    .preferredColorScheme(.dark)
}
