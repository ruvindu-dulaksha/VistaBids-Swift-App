//
//  NewPostView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-09.
//

import SwiftUI
import PhotosUI
import CoreLocation

struct NewPostView: View {
    @ObservedObject var communityService: CommunityService
    @StateObject private var imageUploadService = ImageUploadService()
    @Environment(\.dismiss) var dismiss
    
    @State private var postContent = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var selectedImageData: [Data] = []
    @State private var showingImagePicker = false
    @State private var showingLocationPicker = false
    @State private var selectedLocationName: String = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedLocation: PostLocation?
    @State private var isPosting = false
    @State private var showingGroupPicker = false
    @State private var selectedGroup: CommunityGroup?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content editor
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Text editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's happening?")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextEditor(text: $postContent)
                                .frame(minHeight: 150)
                                .padding(12)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Selected location
                        if let location = selectedLocation {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text(location.name)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button("Remove") {
                                    selectedLocation = nil
                                selectedLocationName = ""
                                selectedCoordinate = nil
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Selected group
                        if let group = selectedGroup {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.blue)
                                Text("Posting to: \(group.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button("Remove") {
                                    selectedGroup = nil
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Selected images
                        if !selectedImageData.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Selected Images (\(selectedImageData.count)/5)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(selectedImageData.enumerated()), id: \.offset) { index, imageData in
                                            if let uiImage = UIImage(data: imageData) {
                                                ZStack(alignment: .topTrailing) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 120, height: 120)
                                                        .cornerRadius(12)
                                                        .clipped()
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                        )
                                                    
                                                    Button(action: {
                                                        removeImage(at: index)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(.white)
                                                            .background(
                                                                Circle()
                                                                    .fill(Color.black.opacity(0.7))
                                                                    .frame(width: 24, height: 24)
                                                            )
                                                    }
                                                    .padding(6)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                
                // Action buttons
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 20) {
                        // Photo picker
                        PhotosPicker(selection: $selectedImages, maxSelectionCount: 5, matching: .images) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        // Location picker
                        Button(action: { showingLocationPicker = true }) {
                            Image(systemName: "location")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        // Group picker
                        Button(action: { showingGroupPicker = true }) {
                            Image(systemName: "person.3")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        // Character count
                        Text("\(postContent.count)/500")
                            .font(.caption)
                            .foregroundColor(postContent.count > 500 ? .red : .secondary)
                    }
                    .padding(16)
                }
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createPost()
                    }
                    .fontWeight(.semibold)
                    .disabled(postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || postContent.count > 500 || isPosting)
                }
            }
            .onChange(of: selectedImages) { _, newItems in
                handleImageSelection(newItems)
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $selectedLocationName, selectedCoordinate: $selectedCoordinate)
                    .onDisappear {
                        updateSelectedLocation()
                    }
            }
            .sheet(isPresented: $showingGroupPicker) {
                GroupPickerView(selectedGroup: $selectedGroup, groups: communityService.groups)
            }
        }
    }
    
    private func createPost() {
        isPosting = true
        
        Task {
            var imageURLs: [String] = []
            
            // Upload actual images if any are selected
            if !selectedImageData.isEmpty {
                do {
                    // Convert Data to UIImage for the upload service
                    var imagesToUpload: [UIImage] = []
                    for imageData in selectedImageData {
                        if let uiImage = UIImage(data: imageData) {
                            imagesToUpload.append(uiImage)
                        }
                    }
                    
                    // Generate unique post ID for organizing images
                    let postId = UUID().uuidString
                    
                    // Upload images using the ImageUploadService
                    imageURLs = try await imageUploadService.uploadPropertyImages(imagesToUpload, propertyId: "community_post_\(postId)")
                    
                    print("✅ Successfully uploaded \(imageURLs.count) images for community post")
                } catch {
                    print("❌ Failed to upload images: \(error.localizedDescription)")
                    // Continue with post creation even if image upload fails
                }
            }
            
            await communityService.createPost(
                content: postContent,
                imageURLs: imageURLs,
                location: selectedLocation,
                groupId: selectedGroup?.id
            )
            
            await MainActor.run {
                isPosting = false
                dismiss()
            }
        }
    }
    
    private func handleImageSelection(_ newItems: [PhotosPickerItem]) {
        Task {
            selectedImageData = []
            for item in newItems {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    selectedImageData.append(data)
                }
            }
        }
    }
    
    private func removeImage(at index: Int) {
        selectedImageData.remove(at: index)
        selectedImages.remove(at: index)
    }
    
    private func updateSelectedLocation() {
        if !selectedLocationName.isEmpty, let coordinate = selectedCoordinate {
            selectedLocation = PostLocation(
                name: selectedLocationName,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                address: selectedLocationName
            )
        } else {
            selectedLocation = nil
        }
    }
}

// MARK: - Group Picker View
struct GroupPickerView: View {
    @Binding var selectedGroup: CommunityGroup?
    let groups: [CommunityGroup]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(groups) { group in
                Button(action: {
                    selectedGroup = group
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(group.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Select Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NewPostView(communityService: CommunityService())
}
