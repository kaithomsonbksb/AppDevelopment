import SwiftUI

struct PerkPickerView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    @State private var selectedPerk: Perk?
    var body: some View {
        NavigationView {
            List(PerkCatalogue.all) { perk in
                Button(action: {
                    selectedPerk = perk
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(perk.name).font(.headline)
                            Text(perk.description).font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedPerk == perk {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Pick a Perk")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let perk = selectedPerk {
                            viewModel.addPerk(perk)
                            isPresented = false
                        }
                    }.disabled(selectedPerk == nil)
                }
            }
        }
    }
}