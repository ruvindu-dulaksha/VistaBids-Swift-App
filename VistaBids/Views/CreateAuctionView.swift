import SwiftUI
import PhotosUI
import MapKit
import FirebaseFirestore

struct CreateAuctionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var biddingService = BiddingService()
    @StateObject private var locationService = LocationManager()
    
    // Basic property info
    @State private var title = ""
    @State private var description = ""
    @State private var startingPrice = ""
    @State private var category: PropertyCategory = .residential
    
    // Property details
    @State private var bedrooms = 1
    @State private var bathrooms = 1
    @State private var area = ""
    @State private var parking = 0
    @State private var propertyType = "House"
    @State private var yearBuilt = Calendar.current.component(.year, from: Date())
    
    // Address
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var country = "USA"
    
    // Media
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var uploadedImageURLs: [String] = []
    @State private var selectedVideos: [PhotosPickerItem] = []
    @State private var uploadedVideoURLs: [String] = []
    @State private var isUploadingMedia = false
    
    // Auction settings
    @State private var auctionStartTime = Date()
    @State private var auctionDuration: AuctionDuration = .thirtyMinutes
    
    // AR & 360
    @State private var arModelURL = ""
    @State private var walkthroughVideoURL = ""
    @State private var panoramicImages: [PanoramicImage] = []
    
    // Location
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var selectedLocationName = ""
    @State private var showLocationPicker = false
    
    // UI State
    @State private var isCreating = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var creationSuccess = false
    @State private var currentStep = 0
    
    private let steps = [
        "Basic Info",
        "Property Details", 
        "Location & Address",
        "Media Upload",
        "Auction Settings",
        "Review"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress indicator
                    progressIndicator
                    
                    // Step content
                    stepContent
                    
                    // Navigation buttons
                    navigationButtons
                }
                .padding()
            }
            .navigationTitle("Create Auction")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Validation Error", isPresented: $showValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
            .alert("Success!", isPresented: $creationSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your auction has been created successfully!")
            }
        }
    }
    
    //Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            
            Text("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            basicInfoStep
        case 1:
            propertyDetailsStep
        case 2:
            locationStep
        case 3:
            mediaUploadStep
        case 4:
            auctionSettingsStep
        case 5:
            reviewStep
        default:
            EmptyView()
        }
    }
    
    //  Basic Info
    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Basic Information",
                subtitle: "Tell us about your property"
            )
            
            VStack(alignment: .leading, spacing: 16) {
                FormField(
                    title: "Property Title",
                    placeholder: "Beautiful 3BR Home in Downtown",
                    text: $title
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Starting Price")
                        .font(.headline)
                    
                    HStack {
                        Text("$")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        TextField("Enter starting price", text: $startingPrice)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                    
                    Picker("Category", selection: $category) {
                        ForEach(PropertyCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }
    
    // Property Details
    private var propertyDetailsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Property Details",
                subtitle: "Specific details about your property"
            )
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Bedrooms")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Stepper(value: $bedrooms, in: 0...10) {
                        Text("\(bedrooms)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    Text("Bathrooms")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Stepper(value: $bathrooms, in: 0...10) {
                        Text("\(bathrooms)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    Text("Area (sq ft)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Enter area", text: $area)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading) {
                    Text("Parking Spaces")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Stepper(value: $parking, in: 0...10) {
                        Text("\(parking)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                FormField(
                    title: "Property Type",
                    placeholder: "House, Apartment, Condo, etc.",
                    text: $propertyType
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Year Built")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Year Built", selection: $yearBuilt) {
                        ForEach((1900...Calendar.current.component(.year, from: Date())), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 100)
                }
            }
        }
    }
    
    // Location
    private var locationStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Location & Address",
                subtitle: "Where is your property located?"
            )
            
            VStack(spacing: 16) {
                FormField(
                    title: "Street Address",
                    placeholder: "123 Main Street",
                    text: $street
                )
                
                HStack(spacing: 12) {
                    FormField(
                        title: "City",
                        placeholder: "City",
                        text: $city
                    )
                    
                    FormField(
                        title: "State",
                        placeholder: "State",
                        text: $state
                    )
                }
                
                HStack(spacing: 12) {
                    FormField(
                        title: "Postal Code",
                        placeholder: "12345",
                        text: $postalCode
                    )
                    
                    FormField(
                        title: "Country",
                        placeholder: "Country",
                        text: $country
                    )
                }
                
                Button("📍 Select Location on Map") {
                    showLocationPicker = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                if let location = selectedLocation {
                    Text("📍 Location: \(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(
                selectedLocation: $selectedLocation,
                locationName: $selectedLocationName,
                isPresented: $showLocationPicker
            )
        }
    }
    
    //  Media Upload
    private var mediaUploadStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Media Upload",
                subtitle: "Add photos and videos of your property"
            )
            
            VStack(spacing: 20) {
                // Image upload section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Property Photos")
                        .font(.headline)
                    
                    PhotosPicker(
                        selection: $selectedImages,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            
                            Text("Select Photos")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            
                            Text("Choose up to 10 photos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }
                    
                    if !selectedImages.isEmpty {
                        Text("Selected: \(selectedImages.count) images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Video upload section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Property Videos")
                        .font(.headline)
                    
                    PhotosPicker(
                        selection: $selectedVideos,
                        maxSelectionCount: 3,
                        matching: .videos
                    ) {
                        VStack(spacing: 12) {
                            Image(systemName: "video.and.waveform")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                            
                            Text("Select Videos")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            
                            Text("Choose up to 3 videos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }
                    
                    if !selectedVideos.isEmpty {
                        Text("Selected: \(selectedVideos.count) videos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Optional AR model URL
                FormField(
                    title: "AR Model URL (Optional)",
                    placeholder: "https://example.com/model.usdz",
                    text: $arModelURL
                )
                
                // Optional walkthrough video URL
                FormField(
                    title: "Walkthrough Video URL (Optional)",
                    placeholder: "https://youtu.be/QrheSm3RfwE?si=mUlvsgJcnYXnh-Ou",
                    text: $walkthroughVideoURL
                )
            }
        }
    }
    
    //  Auction Settings
    private var auctionSettingsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Auction Settings",
                subtitle: "Configure your auction timing and duration"
            )
            
            AuctionSchedulePicker(
                startTime: $auctionStartTime,
                duration: $auctionDuration
            )
        }
    }
    
    //  Review
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Review & Create",
                subtitle: "Review your auction details before publishing"
            )
            
            VStack(spacing: 16) {
                ReviewSection(title: "Basic Information") {
                    ReviewRow(label: "Title", value: title)
                    ReviewRow(label: "Starting Price", value: "$\(startingPrice)")
                    ReviewRow(label: "Category", value: category.rawValue.capitalized)
                }
                
                ReviewSection(title: "Property Details") {
                    ReviewRow(label: "Bedrooms", value: "\(bedrooms)")
                    ReviewRow(label: "Bathrooms", value: "\(bathrooms)")
                    ReviewRow(label: "Area", value: "\(area) sq ft")
                    ReviewRow(label: "Parking", value: "\(parking) spaces")
                }
                
                ReviewSection(title: "Location") {
                    ReviewRow(label: "Address", value: "\(street), \(city), \(state) \(postalCode)")
                }
                
                ReviewSection(title: "Auction Schedule") {
                    ReviewRow(label: "Start Time", value: formatDate(auctionStartTime))
                    ReviewRow(label: "Duration", value: auctionDuration.displayText)
                    ReviewRow(label: "End Time", value: formatDate(auctionStartTime.addingTimeInterval(auctionDuration.timeInterval)))
                }
                
                ReviewSection(title: "Media") {
                    ReviewRow(label: "Photos", value: "\(selectedImages.count) selected")
                    ReviewRow(label: "Videos", value: "\(selectedVideos.count) selected")
                }
            }
        }
    }
    
    // Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Previous") {
                    currentStep -= 1
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(currentStep == steps.count - 1 ? "Create Auction" : "Next") {
                if currentStep == steps.count - 1 {
                    createAuction()
                } else {
                    nextStep()
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canProceed ? Color.blue : Color.gray)
            .cornerRadius(12)
            .disabled(!canProceed || isCreating)
            .overlay(
                Group {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            )
        }
    }
    
    
    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !title.isEmpty && !startingPrice.isEmpty && Double(startingPrice) != nil
        case 1:
            return !area.isEmpty && !propertyType.isEmpty
        case 2:
            return !street.isEmpty && !city.isEmpty && !state.isEmpty && !postalCode.isEmpty
        case 3:
            return !selectedImages.isEmpty 
        case 4:
            return true 
        case 5:
            return true
        default:
            return false
        }
    }
    
    
    private func nextStep() {
        if validateCurrentStep() {
            currentStep += 1
        }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 0:
            if title.isEmpty {
                showValidation("Please enter a property title")
                return false
            }
            if startingPrice.isEmpty || Double(startingPrice) == nil {
                showValidation("Please enter a valid starting price")
                return false
            }
        case 1:
            if area.isEmpty {
                showValidation("Please enter the property area")
                return false
            }
        case 2:
            if street.isEmpty || city.isEmpty || state.isEmpty || postalCode.isEmpty {
                showValidation("Please fill in all address fields")
                return false
            }
        case 3:
            if selectedImages.isEmpty {
                showValidation("Please select at least one photo")
                return false
            }
        default:
            break
        }
        return true
    }
    
    private func showValidation(_ message: String) {
        validationMessage = message
        showValidationAlert = true
    }
    
    private func createAuction() {
        guard validateCurrentStep() else { return }
        
        isCreating = true
        
        Task {
            do {
                
                if !selectedImages.isEmpty {
                    
                    uploadedImageURLs = ["https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800"] 
                }
                
                // Create the auction
                try await biddingService.createAuctionProperty(
                    title: title,
                    description: description,
                    startingPrice: Double(startingPrice) ?? 0,
                    images: uploadedImageURLs,
                    videos: uploadedVideoURLs,
                    arModelURL: arModelURL.isEmpty ? nil : arModelURL,
                    address: PropertyAddress(
                        street: street,
                        city: city,
                        state: state,
                        postalCode: postalCode,
                        country: country
                    ),
                    location: GeoPoint(
                        latitude: selectedLocation?.latitude ?? 0,
                        longitude: selectedLocation?.longitude ?? 0
                    ),
                    features: PropertyFeatures(
                        bedrooms: bedrooms,
                        bathrooms: bathrooms,
                        area: Double(area) ?? 0,
                        yearBuilt: yearBuilt,
                        parkingSpaces: parking,
                        hasGarden: false,
                        hasPool: false,
                        hasGym: false,
                        floorNumber: nil,
                        totalFloors: nil,
                        propertyType: propertyType
                    ),
                    auctionStartTime: auctionStartTime,
                    auctionEndTime: Calendar.current.date(byAdding: .minute, value: auctionDuration.minutes, to: auctionStartTime) ?? auctionStartTime,
                    auctionDuration: auctionDuration,
                    category: category,
                    panoramicImages: panoramicImages,
                    walkthroughVideoURL: walkthroughVideoURL.isEmpty ? nil : walkthroughVideoURL
                )
                
                await MainActor.run {
                    isCreating = false
                    creationSuccess = true
                }
                
            } catch {
                await MainActor.run {
                    isCreating = false
                    validationMessage = error.localizedDescription
                    showValidationAlert = true
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct ReviewSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            VStack(spacing: 8) {
                content
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// LocationPickerView is defined in LocationPickerView.swift

#Preview {
    CreateAuctionView()
}
