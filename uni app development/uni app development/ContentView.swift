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
            VStack(spacing: 24) {
                Text("Welcome to Coastline Perks!")
                    .font(.title)
                    .padding()
                Button(action: {
                    loginSystemModel.isLoggedIn = false
                    loginSystemModel.email = ""
                    loginSystemModel.password = ""
                    loginSystemModel.error = nil
                }) {
                    Text("Logout")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        } else {
            LoginView(viewModel: loginSystemModel)
        }
    }
}

#Preview {
    ContentView()
}
