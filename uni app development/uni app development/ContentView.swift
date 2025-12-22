//
//  ContentView.swift
//  uni app development
//
//  Created by "Kai Thomson, Vodafone" on 22/12/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var loginViewModel = LoginViewModel()

    var body: some View {
        if loginViewModel.isLoggedIn {
            // Placeholder for main app content
            Text("Welcome to Coastline Perks!")
                .font(.title)
                .padding()
        } else {
            LoginView(viewModel: loginViewModel)
        }
    }
}

#Preview {
    ContentView()
}
