//
//  ContentView.swift
//  DemonicEleven
//
//  Created by David Martens on 27.07.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            MainMenuView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
