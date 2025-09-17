//
//  AddPropertyForAuctionView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-16.
//

import SwiftUI
import PhotosUI
import MapKit
import FirebaseFirestore
import FirebaseAuth
import Foundation

// Import required models
import FirebaseFirestore

struct AddPropertyForAuctionView: View {
    let biddingService: BiddingService
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: APIService
    @StateObject private var ownershipService = PropertyOwnershipService()
    
    // Basic Info
    @State private var title = ""
    @State private var description = ""
    @State private var category: PropertyCategory = .residential
    @State private var startingPrice = ""
    
    // Property Features
    @State private var bedrooms = 1
    @State private var bathrooms = 1
    @State private var area = ""
    @State private var yearBuilt = ""
    @State private var parkingSpaces = 0
    @State private var hasGarden = false
    @State private var hasPool = false
    @State private var hasGym = false
    @State private var floorNumber = ""
    @State private var totalFloors = ""
    @State private var propertyType = "House"
    
    // Address
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var country = "Sri Lanka"
    
    // Auction Details
    @State private var auctionStartDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var auctionDuration: AuctionDuration = .thirtyMinutes
    
    // Media
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var selectedVideos: [PhotosPickerItem] = []
    @State private var propertyImages: [UIImage] = []
    @State private var isUploading = false
    
    // AR/Panoramic Features
    @State private var selectedPanoramicImages: [PhotosPickerItem] = []
    @State private var panoramicImages: [UIImage] = []
    @State private var walkthroughVideoURL = ""
    @State private var showingImageUploadService = false
    @State private var showingARCapture = false
    @State private var arCapturedImages: [UIImage] = []
    
    // Location
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var selectedLocationName = ""
    @State private var showingLocationPicker = false
    
    // Validation
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var isBasicInfoValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        !startingPrice.isEmpty &&
        startingPriceValue > 0
    }
    
    private var isAreaValid: Bool {
        !area.isEmpty && areaValue > 0
    }
    
    private var isAddressValid: Bool {
        !street.isEmpty &&
        !city.isEmpty &&
        !state.isEmpty &&
        !postalCode.isEmpty &&
        !country.isEmpty
    }
    
    private var isFormValid: Bool {
        isBasicInfoValid &&
        isAreaValid &&
        isAddressValid &&
        selectedLocation != nil
    }
    
    private var basicInfoValidationMessage: String {
        if title.isEmpty { return "Please enter a property title" }
        if description.isEmpty { return "Please enter a property description" }
        if startingPrice.isEmpty || startingPriceValue <= 0 { return "Please enter a valid starting price" }
        return ""
    }
    
    private var areaValidationMessage: String {
        if area.isEmpty || areaValue <= 0 { return "Please enter a valid property area" }
        return ""
    }
    
    private var addressValidationMessage: String {
        if street.isEmpty || city.isEmpty || state.isEmpty || postalCode.isEmpty || country.isEmpty {
            return "Please complete all address fields"
        }
        if selectedLocation == nil { return "Please select location on map" }
        return ""
    }
    
    private var validationMessage: String {
        let basicMessage = basicInfoValidationMessage
        if !basicMessage.isEmpty { return basicMessage }
        
        let areaMessage = areaValidationMessage
        if !areaMessage.isEmpty { return areaMessage }
        
        let addressMessage = addressValidationMessage
        if !addressMessage.isEmpty { return addressMessage }
        
        return ""
    }
    
    private var startingPriceValue: Double {
        let value = Double(startingPrice) ?? 0
        return (value.isNaN || value.isInfinite || value <= 0) ? 0 : value
    }
    
    private var areaValue: Double {
        let value = Double(area) ?? 0
        return (value.isNaN || value.isInfinite || value <= 0) ? 0 : value
    }
    
    private var yearBuiltValue: Int? {
        if yearBuilt.isEmpty {
            return nil
        }
        return Int(yearBuilt)
    }
    
    private var floorNumberValue: Int? {
        if floorNumber.isEmpty {
            return nil
        }
        return Int(floorNumber)
    }
    
    private var totalFloorsValue: Int? {
        if totalFloors.isEmpty {
            return nil
        }
        return Int(totalFloors)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Property Title*", text: $title)
                    
                    Picker("Category*", selection: $category) {
                        ForEach(PropertyCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized)
                                .tag(category)
                        }
                    }
                    
                    TextField("Starting Price*", text: $startingPrice)
                        .keyboardType(.numberPad)
                    
                    TextField("Property Type (e.g., House, Apartment)", text: $propertyType)
                } header: {
                    Text("Basic Information")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Section {
                    TextField("Describe your property...*", text: $description, axis: .vertical)
                        .lineLimit(5...10)
                } header: {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Section {
                    HStack {
                        Text("Bedrooms")
                        Spacer()
                        Stepper("\(bedrooms)", value: $bedrooms, in: 1...20)
                    }
                    
                    HStack {
                        Text("Bathrooms")
                        Spacer()
                        Stepper("\(bathrooms)", value: $bathrooms, in: 1...20)
                    }
                    
                    TextField("Area (sq ft)*", text: $area)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Property Features")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Section {
                    TextField("Street Address*", text: $street)
                    TextField("City*", text: $city)
                    TextField("State/Province*", text: $state)
                    TextField("Postal Code*", text: $postalCode)
                    TextField("Country*", text: $country)
                    
                    Button(action: { showingLocationPicker = true }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(selectedLocation != nil ? .green : .accentColor)
                            
                            if selectedLocation != nil {
                                Text("✓ Location Selected")
                                    .foregroundColor(.green)
                            } else {
                                Text("Select Location on Map*")
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Address*")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Section {
                    DatePicker(
                        "Auction Start Date",
                        selection: $auctionStartDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    
                    Picker("Auction Duration", selection: $auctionDuration) {
                        ForEach(AuctionDuration.allCases, id: \.self) { duration in
                            Text(duration.displayText)
                                .tag(duration)
                        }
                    }
                } header: {
                    Text("Auction Details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Section {
                    PhotosPicker(
                        selection: $selectedImages,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(.accentColor)
                            Text("Select Property Images")
                                .foregroundColor(.primary)
                            Spacer()
                            if !propertyImages.isEmpty {
                                Text("\(propertyImages.count) selected")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    if !propertyImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<propertyImages.count, id: \.self) { index in
                                    Image(uiImage: propertyImages[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(height: 90)
                    }
                } header: {
                    Text("Property Images")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Section {
                    // AR Capture Button - Only for authenticated users
                    if ownershipService.canCaptureImages() {
                        Button(action: { showingARCapture = true }) {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                    .foregroundColor(.purple.opacity(0.8))
                                Text("Capture 360° AR Panorama")
                                    .foregroundColor(.primary)
                                Spacer()
                                if !arCapturedImages.isEmpty {
                                    Text("\(arCapturedImages.count) captured")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(isUploading)
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.orange)
                            Text("Please log in to capture panoramic images")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Display AR captured images
                    if !arCapturedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<arCapturedImages.count, id: \.self) { index in
                                    Image(uiImage: arCapturedImages[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 60)
                                        .clipped()
                                        .cornerRadius(8)
                                        .overlay(
                                            Text("AR 360°")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(4)
                                                .background(Color.purple.opacity(0.8))
                                                .cornerRadius(4),
                                            alignment: .topTrailing
                                        )
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(height: 70)
                    }
                    
                    // Manual Photo Picker for Panoramic Images - Only for authenticated users
                    if ownershipService.canCaptureImages() {
                        PhotosPicker(
                            selection: $selectedPanoramicImages,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .foregroundColor(.accentColor)
                                Text("Or Select 360° Images from Gallery")
                                    .foregroundColor(.primary)
                                Spacer()
                                if !panoramicImages.isEmpty {
                                    Text("\(panoramicImages.count) selected")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                        }
                        .disabled(isUploading)
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.orange)
                            Text("Please log in to select panoramic images")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if !panoramicImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<panoramicImages.count, id: \.self) { index in
                                    Image(uiImage: panoramicImages[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 60)
                                        .clipped()
                                        .cornerRadius(8)
                                        .overlay(
                                            Text("360°")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(4)
                                                .background(Color.blue.opacity(0.8))
                                                .cornerRadius(4),
                                            alignment: .topTrailing
                                        )
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(height: 70)
                    }
                    
                    TextField("Video Walkthrough URL (Optional)", text: $walkthroughVideoURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    Button(action: { showingImageUploadService = true }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundColor(.green.opacity(0.8))
                            Text("Upload Images to Cloud")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("AR/Panoramic Features")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // Submit Section - Professional and smooth design
                Section {
                    Button(action: submitProperty) {
                        HStack {
                            Spacer()
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                                Text("Submitting...")
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .fontWeight(.medium)
                            } else {
                                Text("Submit Property for Auction")
                                    .foregroundColor(.white)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: isFormValid && !isUploading 
                                    ? [Color.blue.opacity(0.8), Color.blue] 
                                    : [Color.gray.opacity(0.5), Color.gray.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: isFormValid && !isUploading ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid || isUploading)
                    .animation(.easeInOut(duration: 0.2), value: isFormValid)
                    
                    if !isFormValid {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("List Property")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $selectedLocationName, selectedCoordinate: $selectedLocation)
            }
            .sheet(isPresented: $showingImageUploadService) {
                ImageUploadServiceView()
            }
            .sheet(isPresented: $showingARCapture) {
                ARPanoramaCaptureView(capturedImages: $arCapturedImages, isPresented: $showingARCapture)
            }
            .onChange(of: selectedImages) { _ in
                loadImages()
            }
            .onChange(of: selectedPanoramicImages) { _ in
                loadPanoramicImages()
            }
            .alert("Validation Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadImages() {
        Task {
            var images: [UIImage] = []
            
            for item in selectedImages {
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
    
    private func loadPanoramicImages() {
        Task {
            var images: [UIImage] = []
            
            for item in selectedPanoramicImages {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            await MainActor.run {
                self.panoramicImages = images
            }
        }
    }
    
    private func submitProperty() {
        guard !title.isEmpty else {
            alertMessage = "Please enter a property title."
            showingAlert = true
            return
        }
        
        guard !description.isEmpty else {
            alertMessage = "Please enter a property description."
            showingAlert = true
            return
        }
        
        guard !startingPrice.isEmpty, let startingPriceValue = Double(startingPrice), startingPriceValue > 0 else {
            alertMessage = "Please enter a valid starting price."
            showingAlert = true
            return
        }
        
        guard !area.isEmpty, let areaValue = Double(area), areaValue > 0 else {
            alertMessage = "Please enter a valid area."
            showingAlert = true
            return
        }
        
        guard !street.isEmpty, !city.isEmpty, !state.isEmpty, !postalCode.isEmpty, !country.isEmpty else {
            alertMessage = "Please fill in all address fields."
            showingAlert = true
            return
        }
        
        guard let location = selectedLocation else {
            alertMessage = "Please select a location on the map."
            showingAlert = true
            return
        }
        
        isUploading = true
        
        Task {
            do {
                // Convert PhotosPickerItems to UIImages first
                let imageUploadService = ImageUploadService()
                let propertyId = UUID().uuidString
                
                var imageURLs: [String] = []
                if !selectedImages.isEmpty {
                    // Convert PhotosPickerItems to UIImages
                    var uiImages: [UIImage] = []
                    for item in selectedImages {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            uiImages.append(uiImage)
                        }
                    }
                    
                    // Upload the converted UIImages
                    if !uiImages.isEmpty {
                        let urls = try await imageUploadService.uploadPropertyImages(uiImages, propertyId: propertyId)
                        imageURLs = urls
                    }
                }
                
                // Create panoramic images array from both AR captured images and gallery selected images
                var panoramicImageArray: [PanoramicImage] = []
                
                // Process AR captured images first
                for (index, image) in arCapturedImages.enumerated() {
                    var imageURL: String
                    do {
                        imageURL = try await imageUploadService.uploadPanoramicImage(image, propertyId: propertyId, roomType: .livingRoom)
                    } catch {
                        print("AR panoramic upload failed, using local fallback: \(error)")
                        // Enhanced local storage fallback
                        if let imageData = image.jpegData(compressionQuality: 0.9),
                           let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            
                            // Create images directory if it doesn't exist
                            let imagesDir = documentsPath.appendingPathComponent("images")
                            if !FileManager.default.fileExists(atPath: imagesDir.path) {
                                try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
                            }
                            
                            let fileName = "ar_panoramic_\(propertyId)_\(index)_\(Int(Date().timeIntervalSince1970)).jpg"
                            let filePath = imagesDir.appendingPathComponent(fileName)
                            try imageData.write(to: filePath)
                            imageURL = "local://images/\(fileName)"
                            print(" Saved AR panoramic locally: \(imageURL)")
                        } else {
                            imageURL = "placeholder_ar_panoramic_\(index)"
                        }
                    }
                    
                    panoramicImageArray.append(PanoramicImage(
                        id: UUID().uuidString,
                        imageURL: imageURL,
                        title: "AR Capture \(index + 1)",
                        description: "360° AR panoramic view",
                        roomType: .livingRoom,
                        captureDate: Date(),
                        isAREnabled: true
                    ))
                }
                
                // Process gallery selected panoramic images
                for (index, image) in panoramicImages.enumerated() {
                    var imageURL: String
                    do {
                        imageURL = try await imageUploadService.uploadPanoramicImage(image, propertyId: propertyId, roomType: .livingRoom)
                    } catch {
                        print("Gallery panoramic upload failed, using local fallback: \(error)")
                        // Enhanced local storage fallback
                        if let imageData = image.jpegData(compressionQuality: 0.9),
                           let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            
                            // Create images directory if it doesn't exist
                            let imagesDir = documentsPath.appendingPathComponent("images")
                            if !FileManager.default.fileExists(atPath: imagesDir.path) {
                                try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
                            }
                            
                            let fileName = "gallery_panoramic_\(propertyId)_\(index)_\(Int(Date().timeIntervalSince1970)).jpg"
                            let filePath = imagesDir.appendingPathComponent(fileName)
                            try imageData.write(to: filePath)
                            imageURL = "local://images/\(fileName)"
                            print(" Saved gallery panoramic locally: \(imageURL)")
                        } else {
                            imageURL = "placeholder_gallery_panoramic_\(index)"
                        }
                    }
                    
                    panoramicImageArray.append(PanoramicImage(
                        id: UUID().uuidString,
                        imageURL: imageURL,
                        title: "Gallery Image \(index + 1)",
                        description: "360° panoramic view",
                        roomType: .livingRoom,
                        captureDate: Date(),
                        isAREnabled: false
                    ))
                }
                
                // Validate video URL if provided
                let videoURL: String? = walkthroughVideoURL.isEmpty ? nil : walkthroughVideoURL
                
                try await biddingService.createAuctionProperty(
                    title: title,
                    description: description,
                    startingPrice: startingPriceValue,
                    images: imageURLs,
                    videos: [],
                    arModelURL: nil,
                    address: PropertyAddress(
                        street: street,
                        city: city,
                        state: state,
                        postalCode: postalCode,
                        country: country
                    ),
                    location: {
                        let point = GeoPoint(latitude: location.latitude, longitude: location.longitude)
                        return point
                    }(),
                    features: PropertyFeatures(
                        bedrooms: bedrooms,
                        bathrooms: bathrooms,
                        area: areaValue,
                        yearBuilt: yearBuiltValue,
                        parkingSpaces: parkingSpaces > 0 ? parkingSpaces : nil,
                        hasGarden: hasGarden,
                        hasPool: hasPool,
                        hasGym: hasGym,
                        floorNumber: floorNumberValue,
                        totalFloors: totalFloorsValue,
                        propertyType: propertyType
                    ),
                    auctionStartTime: auctionStartDate,
                    auctionEndTime: Calendar.current.date(byAdding: .minute, value: auctionDuration.minutes, to: auctionStartDate) ?? auctionStartDate,
                    auctionDuration: auctionDuration,
                    category: category,
                    panoramicImages: panoramicImageArray,
                    walkthroughVideoURL: videoURL
                )
                
                await MainActor.run {
                    isUploading = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isUploading = false
                    alertMessage = "Failed to create auction: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}


// AuctionDuration enum is now defined in BiddingModels.swift

#Preview {
    AddPropertyForAuctionView(biddingService: BiddingService())
}
