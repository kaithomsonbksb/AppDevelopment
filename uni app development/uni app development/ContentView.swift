//
//  ContentView.swift
//  uni app development
//
//  Created by "Kai Thomson, Vodafone" on 22/12/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .imageScale(.large)
                .foregroundStyle(.yellow)
            Text("You've tapped the button \(count) times!")
                .font(.headline)
            Button("Tap Me") {
                count += 1
            }
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
