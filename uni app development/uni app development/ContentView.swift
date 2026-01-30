//
//  ContentView.swift
//  uni app development
//
//  Created by "Kai Thomson, Vodafone" on 22/12/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var loginSystemModel = LoginSystemModel()

    var body: some View {
        if loginSystemModel.isLoggedIn {
            HomeView(viewModel: HomeViewModel(email: loginSystemModel.email))
        } else {
            LoginView(viewModel: loginSystemModel)
        }
    }
}

#Preview {
    ContentView()
}
