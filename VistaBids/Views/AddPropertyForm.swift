import SwiftUI
import MapKit
import CoreLocation

struct AddPropertyForm: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @ObservedObject var salePropertyService: SalePropertyService
    
    // Form fields
    @State private var propertyTitle = ""
    @State private var propertyDescription = ""
    @State private var price = ""
    @State private var selectedPropertyType: PropertyType = .house
    @State private var bedrooms = 1
    @State private var bathrooms = 1
    @State private var area = ""
    @State private var yearBuilt = ""
    
    // Location
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var locationName = ""
    @State private var showingLocationPicker = false
    
    // Images
    @State private var capturedImages: [UIImage] = []
    @State private var showingARCamera = false
    @State private var showingImagePicker = false
    @State private var selectedImageSource: UIImagePickerController.SourceType = .camera
    
    // Form state
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Property Images Section
                    imageSection
                    
                    // Basic Info Section
                    basicInfoSection
                    
                    // Property Details Section
                    propertyDetailsSection
                    
                    // Location Section
                    locationSection
                    
                    // Submit Button
                    submitButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingARCamera) {
            ARPanoramaCaptureView(
                capturedImages: $capturedImages,
                isPresented: $showingARCamera
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(
                sourceType: selectedImageSource,
                onImageSelected: { image in
                    capturedImages.append(image)
                }
            )
        }
        .sheet(isPresented: $showingLocationPicker) {
            PropertyLocationPicker(
                selectedLocation: $selectedLocation,
                locationName: $locationName,
                isPresented: $showingLocationPicker
            )
        }
        .alert("Property Submission", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("List Your Property")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Fill in the details below to list your property for sale")
                .font(.subheadline)
                .foregroundColor(.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Property Images")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Image grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    if index < capturedImages.count {
                        // Captured image
                        Image(uiImage: capturedImages[index])
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                Button(action: {
                                    capturedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .padding(4),
                                alignment: .topTrailing
                            )
                    } else {
                        // Add image placeholder
                        Button(action: {
                            showImageOptions()
                        }) {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .frame(height: 100)
                                .overlay(
                                    VStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundColor(.gray)
                                        Text("Add Photo")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                    }
                }
            }
            
            // AR Camera button
            Button(action: {
                showingARCamera = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Take 360° Panoramic Photos")
                    Spacer()
                    Image(systemName: "arkit")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding()
                .background(Color.accentBlues.opacity(0.1))
                .foregroundColor(.accentBlues)
                .cornerRadius(12)
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Property Title
                FormField(title: "Property Title", placeholder: "Enter property title", text: $propertyTitle)
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextEditor(text: $propertyDescription)
                        .frame(height: 100)
                        .padding(12)
                        .background(Color.inputFields)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Price
                FormField(title: "Price (LKR)", placeholder: "Enter price", text: $price)
                    .keyboardType(.numberPad)
                
                // Property Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Property Type")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Property Type", selection: $selectedPropertyType) {
                        ForEach(PropertyType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        }
    }
    
    private var propertyDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Property Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Bedrooms and Bathrooms
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bedrooms")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Stepper("\(bedrooms)", value: $bedrooms, in: 1...10)
                            .padding(12)
                            .background(Color.inputFields)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bathrooms")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Stepper("\(bathrooms)", value: $bathrooms, in: 1...10)
                            .padding(12)
                            .background(Color.inputFields)
                            .cornerRadius(12)
                    }
                }
                
                // Area and Year Built
                HStack(spacing: 16) {
                    FormField(title: "Area (sq ft)", placeholder: "e.g., 1200", text: $area)
                        .keyboardType(.numberPad)
                    
                    FormField(title: "Year Built", placeholder: "e.g., 2020", text: $yearBuilt)
                        .keyboardType(.numberPad)
                }
            }
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button(action: {
                showingLocationPicker = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(locationName.isEmpty ? "Select Location" : locationName)
                            .font(.subheadline)
                            .foregroundColor(locationName.isEmpty ? .gray : .primary)
                        
                        if selectedLocation != nil {
                            Text("Tap to change location")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "location.fill")
                        .foregroundColor(.accentBlues)
                }
                .padding()
                .background(Color.inputFields)
                .cornerRadius(12)
            }
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            Task {
                await submitProperty()
            }
        }) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("List Property")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.accentBlues : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isSubmitting)
    }
    
    private var isFormValid: Bool {
        !propertyTitle.isEmpty &&
        !propertyDescription.isEmpty &&
        !price.isEmpty &&
        selectedLocation != nil &&
        !capturedImages.isEmpty
    }
    
    private func showImageOptions() {
        let alert = UIAlertController(title: "Add Photo", message: "Choose how to add a photo", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            selectedImageSource = .camera
            showingImagePicker = true
        })
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            selectedImageSource = .photoLibrary
            showingImagePicker = true
        })
        
        alert.addAction(UIAlertAction(title: "AR Panorama", style: .default) { _ in
            showingARCamera = true
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = scene.windows.first?.rootViewController {
            var topController = rootViewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(alert, animated: true)
        }
    }
    
    private func submitProperty() async {
        guard isFormValid else { return }
        
        isSubmitting = true
        
        // Create new sale property
        let newProperty = SaleProperty(
            id: UUID().uuidString,
            title: propertyTitle,
            description: propertyDescription,
            price: Double(price) ?? 0,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            area: area,
            propertyType: selectedPropertyType,
            address: PropertyAddressOld(
                street: locationName,
                city: "", // Will be populated from reverse geocoding if needed
                state: "", // Will be populated from reverse geocoding if needed
                zipCode: "", // Will be populated from reverse geocoding if needed
                country: "" // Will be populated from reverse geocoding if needed
            ),
            coordinates: PropertyCoordinates(
                latitude: selectedLocation?.latitude ?? 0,
                longitude: selectedLocation?.longitude ?? 0
            ),
            images: [], // Will be populated after image upload
            panoramicImages: [], // Will be populated after panoramic image upload
            walkthroughVideoURL: nil, // Will be populated after video upload
            features: [],
            seller: PropertySeller(
                id: "current_user", // Replace with actual user ID
                name: "Current User", // Replace with actual user name
                email: "user@example.com", // Replace with actual user email
                phone: "+1234567890", // Replace with actual user phone
                profileImageURL: nil,
                rating: 5.0,
                reviewCount: 0,
                verificationStatus: .verified
            ),
            availableFrom: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            status: .active,
            isNew: true
        )
        
        // Add property to service
        do {
            try await salePropertyService.addProperty(newProperty)
            
            // Simulate upload delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isSubmitting = false
                alertMessage = "Property listed successfully!"
                showingAlert = true
            }
        } catch {
            isSubmitting = false
            alertMessage = "Failed to add property: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct AddPropertyFormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: $text)
                .padding(12)
                .background(Color.inputFields)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    AddPropertyForm(salePropertyService: SalePropertyService.shared)
}
