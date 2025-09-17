//
//  PropertyUploadView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-18.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct PropertyUploadView: View {
    @StateObject private var uploadService = ImageUploadService()
    @State private var propertyTitle = ""
    @State private var propertyDescription = ""
    @State private var price = ""
    @State private var bedrooms = 1
    @State private var bathrooms = 1
    @State private var area = ""
    @State private var propertyType: PropertyType = .house
    @State private var selectedImages: [UIImage] = []
    @State private var panoramicImages: [PanoramicImageUpload] = []
    @State private var walkthroughVideoURL: URL?
    
    // UI State
    @State private var showingImagePicker = false
    @State private var showingPanoramicCapture = false
    @State private var showingVideoPicker = false
    @State private var showingLocationPicker = false
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var showingSuccess = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Property Details") {
                    TextField("Property Title", text: $propertyTitle)
                    TextField("Description", text: $propertyDescription, axis: .vertical)
                        .lineLimit(3...6)
                    
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("0", text: $price)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Property Type", selection: $propertyType) {
                        ForEach(PropertyType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    HStack {
                        VStack {
                            Stepper("Bedrooms: \(bedrooms)", value: $bedrooms, in: 1...10)
                        }
                    }
                    
                    HStack {
                        VStack {
                            Stepper("Bathrooms: \(bathrooms)", value: $bathrooms, in: 1...10)
                        }
                    }
                    
                    TextField("Area (sq ft)", text: $area)
                }
                
                Section("Images") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { showingImagePicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Add Property Images")
                                Spacer()
                                Text("\(selectedImages.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !selectedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(0..<selectedImages.count, id: \.self) { index in
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 80, height: 80)
                                            .clipped()
                                            .cornerRadius(8)
                                            .overlay(
                                                Button(action: {
                                                    selectedImages.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                }
                                                .offset(x: 8, y: -8),
                                                alignment: .topTrailing
                                            )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                Section("360° AR Experience") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { showingPanoramicCapture = true }) {
                            HStack {
                                Image(systemName: "view.3d")
                                Text("Add 360° Panoramic Views")
                                Spacer()
                                Text("\(panoramicImages.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !panoramicImages.isEmpty {
                            ForEach(panoramicImages) { panoramic in
                                HStack {
                                    Image(systemName: panoramic.roomType.icon)
                                        .foregroundColor(.accentColor)
                                    VStack(alignment: .leading) {
                                        Text(panoramic.title)
                                            .font(.subheadline)
                                        Text(panoramic.roomType.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    Button(action: {
                                        if let index = panoramicImages.firstIndex(where: { $0.id == panoramic.id }) {
                                            panoramicImages.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                Section("Video Walkthrough") {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: { showingVideoPicker = true }) {
                            HStack {
                                Image(systemName: "video.fill")
                                Text("Add Walkthrough Video")
                                Spacer()
                                if walkthroughVideoURL != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        
                        if let videoURL = walkthroughVideoURL {
                            HStack {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundColor(.accentColor)
                                Text("Video Ready")
                                    .font(.subheadline)
                                Spacer()
                                
                                Button("Remove") {
                                    walkthroughVideoURL = nil
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                if uploadService.isUploading {
                    Section("Upload Progress") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Uploading property...")
                                .font(.subheadline)
                            ProgressView(value: uploadService.uploadProgress)
                            Text("\(Int(uploadService.uploadProgress * 100))% complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Upload") {
                        uploadProperty()
                    }
                    .disabled(propertyTitle.isEmpty || selectedImages.isEmpty || isUploading)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerMultiple(selectedImages: $selectedImages)
            }
            .sheet(isPresented: $showingPanoramicCapture) {
                PanoramicCaptureView(panoramicImages: $panoramicImages)
            }
            .sheet(isPresented: $showingVideoPicker) {
                VideoPickerView(selectedVideoURL: $walkthroughVideoURL)
            }
            .alert("Upload Error", isPresented: .constant(uploadError != nil)) {
                Button("OK") {
                    uploadError = nil
                }
            } message: {
                if let error = uploadError {
                    Text(error)
                }
            }
            .alert("Success!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Property uploaded successfully!")
            }
        }
    }
    
    private func uploadProperty() {
        guard !propertyTitle.isEmpty else { return }
        
        isUploading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isUploading = false
            showingSuccess = true
        }
    }
}

// Panoramic Image Upload Model
struct PanoramicImageUpload: Identifiable {
    let id = UUID()
    let title: String
    let roomType: PanoramicImage.RoomType
    let image: UIImage
    let description: String?
}

//  Multiple Image Picker
struct ImagePickerMultiple: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 10 // Allow up to 10 images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerMultiple
        
        init(_ parent: ImagePickerMultiple) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
        }
    }
}

//  Panoramic Capture View
struct PanoramicCaptureView: View {
    @Binding var panoramicImages: [PanoramicImageUpload]
    @State private var selectedRoomType: PanoramicImage.RoomType = .livingRoom
    @State private var imageTitle = ""
    @State private var imageDescription = ""
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Room Information") {
                    TextField("Title (e.g., Living Room 360°)", text: $imageTitle)
                    
                    Picker("Room Type", selection: $selectedRoomType) {
                        ForEach(PanoramicImage.RoomType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    
                    TextField("Description (optional)", text: $imageDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Capture 360° Image") {
                    VStack(spacing: 16) {
                        Button(action: { showingImagePicker = true }) {
                            VStack {
                                Image(systemName: "camera.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.accentColor)
                                Text("Capture/Select Panoramic Image")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 100)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                }
                
                Text("Tips for 360° Images:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Use a 360° camera or panoramic mode")
                    Text("• Keep the camera steady")
                    Text("• Ensure good lighting")
                    Text("• Remove clutter from the room")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .navigationTitle("Add 360° View")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addPanoramicImage()
                    }
                    .disabled(imageTitle.isEmpty || capturedImage == nil)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                capturedImage = image
            }
        }
    }
    
    private func addPanoramicImage() {
        guard let image = capturedImage, !imageTitle.isEmpty else { return }
        
        let panoramicImage = PanoramicImageUpload(
            title: imageTitle,
            roomType: selectedRoomType,
            image: image,
            description: imageDescription.isEmpty ? nil : imageDescription
        )
        
        panoramicImages.append(panoramicImage)
        dismiss()
    }
}

// Video Picker
struct VideoPickerView: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPickerView
        
        init(_ parent: VideoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.selectedVideoURL = videoURL
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    PropertyUploadView()
}
