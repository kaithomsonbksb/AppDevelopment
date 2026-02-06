import SwiftUI


struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    let onLogout: () -> Void
    @State private var showPerkPicker = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack {
                    if viewModel.isOffline {
                        Text("Offline mode: showing cached perks")
                            .foregroundColor(.orange)
                            .padding(.top)
                    }
                    Text("Assigned Perks")
                        .font(.largeTitle)
                        .padding(.top)
                    if viewModel.isLoading {
                        ProgressView("Loading perks...")
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else if viewModel.assignedPerks.isEmpty {
                        Text(viewModel.isOffline ? "No cached perks available." : "No perks assigned.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List(viewModel.assignedPerks) { perk in
                            VStack(alignment: .leading) {
                                Text(perk.name)
                                    .font(.headline)
                                Text(perk.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                }
                HStack {
                    VStack(alignment: .leading) {
                        HStack(spacing: 6) {
                            Image(systemName: "creditcard")
                                .foregroundColor(.black)
                            Text("\(viewModel.credits)")
                                .bold()
                                .foregroundColor(.black)
                        }
                        .padding(.leading, 16)
                        .padding(.top, 44)
                        Spacer()
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        HStack {
                            Spacer()
                            Button(action: { showPerkPicker = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.green)
                            }
                            .padding([.top, .trailing], 16)
                        }
                        Spacer()
                    }
                }
            }

            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Logout") {
                onLogout()
            })
            .onAppear {
                viewModel.fetchAssignedPerks()
            }
            .sheet(isPresented: $showPerkPicker) {
                PerkPickerView(viewModel: viewModel, isPresented: $showPerkPicker)
            }
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(email: "demo@example.com"), onLogout: {})
}
