import SwiftUI
import PhotosUI
import FirebaseFirestore
import os.log

struct SellPropertyScreen: View {
    @StateObject private var salePropertyService = SalePropertyService.shared
    @State private var showingAddProperty = false
    @State private var searchText = ""
    @State private var selectedFilter: PropertyType? = nil
    @State private var selectedProperty: SaleProperty?
    @State private var showingPropertyDetail = false
    @State private var showingPropertyChat = false
    @State private var showingCallAlert = false
    @State private var showingFilterSheet = false
    @State private var priceRange: ClosedRange<Double> = 0...10_000_000
    @State private var bedroomFilter: Int? = nil
    @State private var bathroomFilter: Int? = nil
    
    private let logger = Logger(subsystem: "co.dulaksha.VistaBids", category: "SellPropertyScreen")
    
    var filteredProperties: [SaleProperty] {
        var filtered = salePropertyService.properties
        
        // Log filtering information for debugging
        print("🔍 Starting filtering: Total properties from Firestore: \(filtered.count)")
        
        // If no filters are applied and search text is empty, return all properties
        let hasNoFilters = searchText.isEmpty && 
                          selectedFilter == nil && 
                          bedroomFilter == nil && 
                          bathroomFilter == nil &&
                          priceRange == (0...10_000_000)
        
        if hasNoFilters {
            print("🔍 No filters applied - showing all \(filtered.count) properties")
            return filtered
        }
        
        // Apply text search if provided
        if !searchText.isEmpty {
            filtered = filtered.filter { property in
                property.title.localizedCaseInsensitiveContains(searchText) ||
                property.address.city.localizedCaseInsensitiveContains(searchText) ||
                property.address.state.localizedCaseInsensitiveContains(searchText)
            }
            print("🔍 After search text filter: \(filtered.count) properties")
        }
        
        // Apply property type filter if selected
        if let selectedFilter = selectedFilter {
            filtered = filtered.filter { $0.propertyType == selectedFilter }
            print("🔍 After property type filter: \(filtered.count) properties")
        }
        
        // Apply price range filter if changed from default
        if priceRange != (0...10_000_000) {
            filtered = filtered.filter { property in
                property.price >= priceRange.lowerBound && property.price <= priceRange.upperBound
            }
            print("🔍 After price range filter: \(filtered.count) properties")
        }
        
        // Apply bedroom filter if selected
        if let bedrooms = bedroomFilter {
            filtered = filtered.filter { $0.bedrooms == bedrooms }
            print("🔍 After bedroom filter (\(bedrooms)): \(filtered.count) properties")
        }
        
        // Apply bathroom filter if selected
        if let bathrooms = bathroomFilter {
            filtered = filtered.filter { $0.bathrooms == bathrooms }
            print("🔍 After bathroom filter (\(bathrooms)): \(filtered.count) properties")
        }
        
        print("🔍 Final filtered count: \(filtered.count) properties")
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                searchSection
                filterSection
                propertyListSection
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddProperty) {
                AddPropertyForm(salePropertyService: salePropertyService)
            }
            .sheet(isPresented: $showingPropertyDetail) {
                if let property = selectedProperty {
                    SalePropertyDetailView(property: property)
                }
            }
            .sheet(isPresented: $showingPropertyChat) {
                if let property = selectedProperty {
                    SalePropertyChatView(property: property)
                }
            }
            .alert("Call Seller", isPresented: $showingCallAlert) {
                Button("Call Now") {
                    makePhoneCall()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let property = selectedProperty {
                    Text("Would you like to call \(property.seller.name) at \(property.seller.phone ?? "N/A")?")
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(
                    priceRange: $priceRange,
                    bedroomFilter: $bedroomFilter,
                    bathroomFilter: $bathroomFilter,
                    onDismiss: { success in
                        if !success {
                            // If dismissed without applying, reset to default values
                            print("🔄 Filter sheet dismissed without applying - keeping current filters")
                        } else {
                            print("✅ Filter sheet applied with filters - Price: \(priceRange.lowerBound) to \(priceRange.upperBound), Bedrooms: \(String(describing: bedroomFilter)), Bathrooms: \(String(describing: bathroomFilter))")
                        }
                    }
                )
            }
            .onAppear {
                logger.info("🏠 SellPropertyScreen appeared, loading properties from Firestore")
                salePropertyService.loadPropertiesFromFirestore()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        salePropertyService.loadPropertiesFromFirestore()
                    }
                    .foregroundColor(.accentBlues)
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Property Sales")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                Text("\(filteredProperties.count) properties for sale")
                    .font(.subheadline)
                    .foregroundColor(.secondaryTextColor)
            }
            
            Spacer()
            
            Button(action: { showingAddProperty = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Sell Property")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentBlues)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var searchSection: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondaryTextColor)
                TextField("Search properties, lands...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.inputFields)
            .cornerRadius(12)
            
            Button(action: {
                showingFilterSheet = true
            }) {
                Image(systemName: "slider.horizontal.3")
                    .padding(12)
                    .background(Color.accentBlues)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    isSelected: selectedFilter == nil,
                    action: { selectedFilter = nil }
                )
                
                ForEach(PropertyType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        isSelected: selectedFilter == type,
                        action: { selectedFilter = type }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
    
    private var propertyListSection: some View {
        ScrollView {
            if salePropertyService.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading properties...")
                        .font(.subheadline)
                        .foregroundColor(.secondaryTextColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if filteredProperties.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "house.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.secondaryTextColor)
                    Text("No Properties Found")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    Text("No properties available for sale at the moment. Add new properties using the 'Sell Property' button above.")
                        .font(.subheadline)
                        .foregroundColor(.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 50)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(filteredProperties) { property in
                        SalePropertyCard(
                            property: property,
                            onBuyTap: { property in
                                selectedProperty = property
                                showingPropertyDetail = true
                            },
                            onChatTap: { property in
                                selectedProperty = property
                                showingPropertyChat = true
                            },
                            onCallTap: { property in
                                selectedProperty = property
                                showingCallAlert = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }
    
    private func makePhoneCall() {
        guard let property = selectedProperty,
              let phoneNumber = property.seller.phone,
              let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

// Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentBlues : Color.inputFields)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .cornerRadius(20)
        }
    }
}

// Sale Property Card
struct SalePropertyCard: View {
    let property: SaleProperty
    let onBuyTap: (SaleProperty) -> Void
    let onChatTap: (SaleProperty) -> Void
    let onCallTap: (SaleProperty) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Property Image
            AsyncImage(url: URL(string: property.images.first ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    Image("loginlogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                @unknown default:
                    Image("loginlogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(height: 200)
            .clipped()
            .overlay(
                VStack {
                    HStack {
                        statusBadge
                        Spacer()
                        priceBadge
                    }
                    .padding(12)
                    Spacer()
                }
            )
            
            VStack(alignment: .leading, spacing: 12) {
                // Property Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(property.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.secondaryTextColor)
                            .font(.caption)
                        Text("\(property.address.city), \(property.address.state)")
                            .font(.subheadline)
                            .foregroundColor(.secondaryTextColor)
                        Spacer()
                    }
                }
                
                // Property Details
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double")
                            .foregroundColor(.secondaryTextColor)
                        Text("\(property.bedrooms)")
                            .font(.caption)
                            .foregroundColor(.secondaryTextColor)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bathtub")
                            .foregroundColor(.secondaryTextColor)
                        Text("\(property.bathrooms)")
                            .font(.caption)
                            .foregroundColor(.secondaryTextColor)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "square")
                            .foregroundColor(.secondaryTextColor)
                        Text(property.area)
                            .font(.caption)
                            .foregroundColor(.secondaryTextColor)
                    }
                    
                    Spacer()
                }
                
                // Seller Info
                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: property.seller.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                    
                    Text(property.seller.name)
                        .font(.caption)
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        Text(String(format: "%.1f", property.seller.rating ?? 0.0))
                            .font(.caption2)
                            .foregroundColor(.secondaryTextColor)
                    }
                    
                    Spacer()
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { onBuyTap(property) }) {
                        HStack {
                            Image(systemName: "eye")
                            Text("View Details")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentBlues)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Button(action: { onChatTap(property) }) {
                        HStack {
                            Image(systemName: "message")
                            Text("Chat")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.inputFields)
                        .foregroundColor(.textPrimary)
                        .cornerRadius(8)
                    }
                    
                    Button(action: { onCallTap(property) }) {
                        HStack {
                            Image(systemName: "phone")
                            Text("Call")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.inputFields)
                        .foregroundColor(.textPrimary)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    var statusBadge: some View {
        Text(property.isNew ? "New" : "Featured")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(property.isNew ? Color.accentBlues : Color.orange)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    var priceBadge: some View {
        Text(formatPrice(property.price))
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.6))
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        let formattedValue = formatter.string(from: NSNumber(value: price)) ?? "0"
        
        if price >= 1_000_000 {
            let millionValue = price / 1_000_000
            return "Rs. \(String(format: "%.1f", millionValue))M"
        } else {
            return "Rs. \(formattedValue)"
        }
    }
}

// Add Sale Property Sheet
struct AddSalePropertySheet: View {
    @ObservedObject var salePropertyService: SalePropertyService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var propertyImages: [UIImage] = []
    @State private var propertyTitle = ""
    @State private var propertyDescription = ""
    @State private var propertyType = PropertyType.house
    @State private var bedrooms = 3
    @State private var bathrooms = 2
    @State private var area = ""
    @State private var price = ""
    @State private var availableFrom = Date()
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = "Sri Lanka"
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    imagePickerView
                    propertyDetailsView
                    addressView
                    availabilityView
                    submitButtonView
                }
                .padding()
            }
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
                        .onChange(of: selectedImages) { _, newItems in
            loadImages(from: newItems)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "house.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentBlues)
            
            Text("List Your Property")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("List your property for sale")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var imagePickerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Property Photos")
                .font(.headline)
            
            PhotosPicker(
                selection: $selectedImages,
                maxSelectionCount: 6,
                matching: .images
            ) {
                if propertyImages.isEmpty {
                    emptyImagePickerView
                } else {
                    filledImagePickerView
                }
            }
        }
    }
    
    private var emptyImagePickerView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.inputFields)
            .frame(height: 120)
            .overlay(
                VStack {
                    Image(systemName: "photo.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.secondaryTextColor)
                    Text("Add Photos")
                        .foregroundColor(.secondaryTextColor)
                }
            )
    }
    
    private var filledImagePickerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<propertyImages.count, id: \.self) { index in
                    Image(uiImage: propertyImages[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                        .clipped()
                }
                
                if propertyImages.count < 6 {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "plus")
                                .foregroundColor(.secondaryTextColor)
                        )
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var propertyDetailsView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Property Title")
                    .font(.headline)
                TextField("Enter property title", text: $propertyTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                TextField("Describe your property", text: $propertyDescription, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(4...8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Property Type")
                    .font(.headline)
                Picker("Property Type", selection: $propertyType) {
                    ForEach(PropertyType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            bedroomBathroomView
            areaView
            priceView
        }
    }
    
    private var bedroomBathroomView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bedrooms")
                    .font(.headline)
                Stepper("\(bedrooms)", value: $bedrooms, in: 1...10)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Bathrooms")
                    .font(.headline)
                Stepper("\(bathrooms)", value: $bathrooms, in: 1...10)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var areaView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Area (sq ft)")
                .font(.headline)
            TextField("e.g., 2,500", text: $area)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
        }
    }
    
    private var priceView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price ($)")
                .font(.headline)
            TextField("Enter property price", text: $price)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
        }
    }
    
    private var addressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Address")
                .font(.headline)
            
            TextField("Street Address", text: $street)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack(spacing: 12) {
                TextField("City", text: $city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("State", text: $state)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack(spacing: 12) {
                TextField("ZIP Code", text: $zipCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                TextField("Country", text: $country)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    private var availabilityView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Availability")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Available From")
                    .font(.subheadline)
                DatePicker("Available From", selection: $availableFrom, displayedComponents: [.date])
                    .datePickerStyle(CompactDatePickerStyle())
            }
        }
    }
    
    private var submitButtonView: some View {
        Button(action: submitProperty) {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Creating Property...")
                }
            } else {
                Text("List Property For Sale")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(isFormValid ? Color.accentBlues : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(!isFormValid || isLoading)
    }
    
    private var isFormValid: Bool {
        !propertyTitle.isEmpty &&
        !propertyDescription.isEmpty &&
        !area.isEmpty &&
        !price.isEmpty &&
        !street.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !zipCode.isEmpty
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            await MainActor.run {
                self.propertyImages = images
            }
        }
    }
    
    private func submitProperty() {
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            do {
                let property = SaleProperty(
                    id: UUID().uuidString,
                    title: propertyTitle,
                    description: propertyDescription,
                    price: Double(price) ?? 0,
                    bedrooms: bedrooms,
                    bathrooms: bathrooms,
                    area: area + " sq ft",
                    propertyType: propertyType,
                    address: PropertyAddressOld(
                        street: street,
                        city: city,
                        state: state,
                        zipCode: zipCode,
                        country: country
                    ),
                    coordinates: PropertyCoordinates(latitude: 6.9271, longitude: 79.8612),
                    images: ["loginlogo"],
                    panoramicImages: [],
                    walkthroughVideoURL: nil,
                    features: [],
                    seller: PropertySeller(
                        id: "current_user",
                        name: "Current User",
                        email: "user@example.com",
                        phone: "+94771234567",
                        profileImageURL: "loginlogo",
                        rating: 4.5,
                        reviewCount: 0,
                        verificationStatus: .verified
                    ),
                    availableFrom: availableFrom,
                    createdAt: Date(),
                    updatedAt: Date(),
                    status: .active,
                    isNew: true
                )
                
                // Convert PhotosPickerItem to UIImage
                        var convertedImages: [UIImage] = []
                        for item in selectedImages {
                            if let data = try await item.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                convertedImages.append(uiImage)
                            }
                        }
                        
                        try await salePropertyService.addProperty(property)
                await MainActor.run {
                    isLoading = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("Error adding property: \(error)")
                }
            }
        }
    }
}

#Preview {
    SellPropertyScreen()
}

//  Filter Sheet View
struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var priceRange: ClosedRange<Double>
    @Binding var bedroomFilter: Int?
    @Binding var bathroomFilter: Int?
    
    var onDismiss: (Bool) -> Void
    
    @State private var minPrice: Double
    @State private var maxPrice: Double
    @State private var selectedBedrooms: Int?
    @State private var selectedBathrooms: Int?
    @State private var filterApplied = false
    
    init(priceRange: Binding<ClosedRange<Double>>, bedroomFilter: Binding<Int?>, bathroomFilter: Binding<Int?>, onDismiss: @escaping (Bool) -> Void = { _ in }) {
        self._priceRange = priceRange
        self._bedroomFilter = bedroomFilter
        self._bathroomFilter = bathroomFilter
        self.onDismiss = onDismiss
        
        // Initialize the local state with the current values
        self._minPrice = State(initialValue: priceRange.wrappedValue.lowerBound)
        self._maxPrice = State(initialValue: priceRange.wrappedValue.upperBound)
        self._selectedBedrooms = State(initialValue: bedroomFilter.wrappedValue)
        self._selectedBathrooms = State(initialValue: bathroomFilter.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Price Range")) {
                    VStack(alignment: .leading) {
                        Text("Min: Rs. \(Int(minPrice))")
                        Slider(value: $minPrice, in: 0...maxPrice, onEditingChanged: { editing in
                            if !editing {
                                // Update binding when user finishes dragging
                                priceRange = minPrice...maxPrice
                            }
                        })
                            .accentColor(.accentBlues)
                        
                        Text("Max: Rs. \(Int(maxPrice))")
                        Slider(value: $maxPrice, in: minPrice...10_000_000, onEditingChanged: { editing in
                            if !editing {
                                // Update binding when user finishes dragging
                                priceRange = minPrice...maxPrice
                            }
                        })
                            .accentColor(.accentBlues)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Bedrooms")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach([1, 2, 3, 4, 5], id: \.self) { number in
                                Button(action: {
                                    if selectedBedrooms == number {
                                        selectedBedrooms = nil
                                    } else {
                                        selectedBedrooms = number
                                    }
                                    // Apply immediately for better user feedback
                                    bedroomFilter = selectedBedrooms
                                }) {
                                    Text("\(number)")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedBedrooms == number ? Color.accentBlues : Color.inputFields)
                                        .foregroundColor(selectedBedrooms == number ? .white : .textPrimary)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Button(action: {
                                selectedBedrooms = nil
                                // Apply immediately for better user feedback
                                bedroomFilter = nil
                            }) {
                                Text("Any")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedBedrooms == nil ? Color.accentBlues : Color.inputFields)
                                    .foregroundColor(selectedBedrooms == nil ? .white : .textPrimary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Bathrooms")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach([1, 2, 3, 4], id: \.self) { number in
                                Button(action: {
                                    if selectedBathrooms == number {
                                        selectedBathrooms = nil
                                    } else {
                                        selectedBathrooms = number
                                    }
                                    // Apply immediately for better user feedback
                                    bathroomFilter = selectedBathrooms
                                }) {
                                    Text("\(number)")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedBathrooms == number ? Color.accentBlues : Color.inputFields)
                                        .foregroundColor(selectedBathrooms == number ? .white : .textPrimary)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Button(action: {
                                selectedBathrooms = nil
                                // Apply immediately for better user feedback
                                bathroomFilter = nil
                            }) {
                                Text("Any")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedBathrooms == nil ? Color.accentBlues : Color.inputFields)
                                    .foregroundColor(selectedBathrooms == nil ? .white : .textPrimary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button("Reset All Filters") {
                        // Reset all filter values
                        minPrice = 0
                        maxPrice = 10_000_000
                        selectedBedrooms = nil
                        selectedBathrooms = nil
                        
                        // Immediately apply the reset
                        priceRange = minPrice...maxPrice
                        bedroomFilter = nil
                        bathroomFilter = nil
                        
                        print("🔄 Reset all filters - showing all properties")
                        
                        // Close the filter sheet after reset
                        filterApplied = true
                        onDismiss(true)
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filter Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        filterApplied = true
                        onDismiss(true)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.accentBlues)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        filterApplied = false
                        onDismiss(false)
                        dismiss()
                    }
                    .foregroundColor(.secondaryTextColor)
                }
            }
        }
    }
    
    private func applyFilters() {
        // Update the price range
        priceRange = minPrice...maxPrice
        
        // Update bedroom filter
        bedroomFilter = selectedBedrooms
        
        // Update bathroom filter
        bathroomFilter = selectedBathrooms
        
        // Log filter values for debugging
        print("📋 Applied filters - Price: \(minPrice) to \(maxPrice), Bedrooms: \(String(describing: selectedBedrooms)), Bathrooms: \(String(describing: selectedBathrooms))")
    }
}

// Sale Property Chat View
struct SalePropertyChatView: View {
    let property: SaleProperty
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var messages: [SaleChatMessage] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Property header
                propertyHeader
                
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                        } else if messages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "message")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("Start Conversation")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("Send a message to \(property.seller.name) about this property")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(messages) { message in
                                    SaleChatMessageView(
                                        message: message,
                                        isCurrentUser: message.senderId == "currentUser"
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message input
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color.inputFields)
                        .cornerRadius(20)
                        .lineLimit(1...5)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(messageText.isEmpty ? Color.gray : Color.accentBlues)
                            .clipShape(Circle())
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadMessages()
            }
        }
    }
    
    private var propertyHeader: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: property.images.first ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_), .empty:
                    Image("loginlogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                @unknown default:
                    Image("loginlogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 50, height: 50)
            .clipped()
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(property.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(formatPrice(property.price))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.accentBlues)
                
                Text("with \(property.seller.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(UIColor.separator)),
            alignment: .bottom
        )
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let newMessage = SaleChatMessage(
            id: UUID().uuidString,
            senderId: "currentUser",
            senderName: "You",
            content: messageText,
            timestamp: Date(),
            propertyId: property.id
        )
        
        messages.append(newMessage)
        messageText = ""
        
        // Simulate seller response after 1-2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...2)) {
            let sellerResponse = SaleChatMessage(
                id: UUID().uuidString,
                senderId: property.seller.id,
                senderName: property.seller.name,
                content: generateSellerResponse(),
                timestamp: Date(),
                propertyId: property.id
            )
            messages.append(sellerResponse)
        }
    }
    
    private func loadMessages() {
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
    
    private func generateSellerResponse() -> String {
        let responses = [
            "Thank you for your interest in this property! I'd be happy to answer any questions.",
            "Great choice! This property has excellent potential. Would you like to schedule a viewing?",
            "I'm available to discuss the details. When would be a good time for you to visit?",
            "This property has been well-maintained. Are you looking for immediate occupancy?",
            "I can provide more details about the neighborhood and amenities. What specific information do you need?"
        ]
        return responses.randomElement() ?? "Thank you for your message!"
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if price >= 1_000_000 {
            let millionValue = price / 1_000_000
            if millionValue.truncatingRemainder(dividingBy: 1) == 0 {
                return "Rs. \(Int(millionValue))M"
            } else {
                return "Rs. \(String(format: "%.1f", millionValue))M"
            }
        } else if price >= 100_000 {
            let hundredThousandValue = price / 100_000
            if hundredThousandValue.truncatingRemainder(dividingBy: 1) == 0 {
                return "Rs. \(Int(hundredThousandValue))L"
            } else {
                return "Rs. \(String(format: "%.1f", hundredThousandValue))L"
            }
        } else {
            let formattedValue = formatter.string(from: NSNumber(value: price)) ?? "0"
            return "Rs. \(formattedValue)"
        }
    }
}

// Sale Chat Message
struct SaleChatMessage: Identifiable {
    let id: String
    let senderId: String
    let senderName: String
    let content: String
    let timestamp: Date
    let propertyId: String
}

//  Sale Chat Message View
struct SaleChatMessageView: View {
    let message: SaleChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isCurrentUser ? .white : .textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.accentBlues : Color.inputFields)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
            }
            
            if !isCurrentUser {
                Spacer(minLength: 50)
            }
        }
        .id(message.id)
    }
}
