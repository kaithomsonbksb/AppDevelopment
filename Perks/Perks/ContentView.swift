//
//  ContentView.swift
//  uni app development
//
//  Created by "Kai Thomson, Vodafone" on 22/12/2025.
//

import SwiftUI

struct ContentView: View {

    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("userEmail") private var userEmail: String = ""
    @StateObject private var loginSystemModel = LoginSystemModel()
    @StateObject private var homeViewModel = HomeViewModel(email: "")

    var body: some View {
        if isLoggedIn {
            HomeView(viewModel: homeViewModel, onLogout: {
                isLoggedIn = false
                userEmail = ""
            })
                .onAppear {
                    homeViewModel.email = userEmail
                }
        } else {
            LoginView(viewModel: loginSystemModel, onLogin: { email in
                isLoggedIn = true
                userEmail = email
                // Determine if offline login occurred
                let isOffline = loginSystemModel.errorMessage?.contains("Offline mode") == true
                homeViewModel.onLoginSuccess(email: email, isOffline: isOffline)
            }, onSignup: { email in
                isLoggedIn = true
                userEmail = email
                homeViewModel.onLoginSuccess(email: email, isOffline: false)
            })
        }
    }
}

#Preview {
    ContentView()
}
