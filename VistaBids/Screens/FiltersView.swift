//
//  FiltersView.swift
//  VistaBids
//
//  Recreated placeholder after original file deletion to restore build.
//  
//
import SwiftUI


struct AuctionFilters: Equatable {
    var minPrice: Double?
    var maxPrice: Double?
    var category: PropertyCategory?
    var showOnlyActive: Bool = false
    var showOnlyWithMedia: Bool = false
    var hasAR: Bool = false
    var hasVideo: Bool = false
    var city: String = ""
}

struct FiltersView: View {
    @Binding var isPresented: Bool
    @Binding var filters: AuctionFilters
    @State private var tempFilters: AuctionFilters

    init(isPresented: Binding<Bool>, filters: Binding<AuctionFilters>) {
        _isPresented = isPresented
        _filters = filters
        _tempFilters = State(initialValue: filters.wrappedValue)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Price Range")) {
                    HStack {
                        TextField("Min", value: $tempFilters.minPrice, format: .number)
                            .keyboardType(.numberPad)
                        Text("-")
                        TextField("Max", value: $tempFilters.maxPrice, format: .number)
                            .keyboardType(.numberPad)
                    }
                }

                Section(header: Text("Category")) {
                    // real categories should come from model
                    Picker("Category", selection: Binding(get: { tempFilters.category ?? PropertyCategory.residential }, set: { tempFilters.category = $0 })) {
                        Text("Residential").tag(PropertyCategory.residential)
                        if let commercial = PropertyCategory.allCases.first(where: { String(describing: $0) == "commercial" }) {
                            Text("Commercial").tag(commercial)
                        }
                    }
                }

                Section(header: Text("Attributes")) {
                    Toggle("Active Only", isOn: $tempFilters.showOnlyActive)
                    Toggle("With Any Media", isOn: $tempFilters.showOnlyWithMedia)
                    Toggle("Has AR", isOn: $tempFilters.hasAR)
                    Toggle("Has Video", isOn: $tempFilters.hasVideo)
                }

                Section(header: Text("Location")) {
                    TextField("City", text: $tempFilters.city)
                }

                if filters != tempFilters {
                    Section {
                        Button(role: .destructive) { resetFilters() } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset Filters")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { applyAndDismiss() }
                        .disabled(!hasChanges)
                }
            }
        }
    }

    private var hasChanges: Bool { tempFilters != filters }

    private func applyAndDismiss() {
        filters = tempFilters
        isPresented = false
    }

    private func resetFilters() {
        tempFilters = AuctionFilters()
    }
}

#Preview {
    FiltersView(isPresented: .constant(true), filters: .constant(AuctionFilters()))
}
