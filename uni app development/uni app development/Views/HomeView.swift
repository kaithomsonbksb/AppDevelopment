import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Assigned Perks")
                    .font(.largeTitle)
                    .padding(.top)
                if viewModel.isLoading {
                    ProgressView("Loading perks...")
                        .padding()
                } else if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.assignedPerks.isEmpty {
                    Text("No perks assigned.")
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
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchAssignedPerks()
            }
        }
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(email: "demo@example.com"))
}
