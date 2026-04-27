//
//  ContentView.swift
//  FRCLive
//
//  Created by Onur Akyüz on 27.04.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("FRCLive")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ContentView()
}
