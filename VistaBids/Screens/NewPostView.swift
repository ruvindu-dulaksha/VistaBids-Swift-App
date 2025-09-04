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
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(selectedImageData.enumerated()), id: \.offset) { index, imageData in
                                        if let uiImage = UIImage(data: imageData) {
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(8)
                                                    .clipped()
                                                
                                                Button(action: {
                                                    removeImage(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                }
                                                .padding(4)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
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
            // In a real app, you would upload images to Firebase Storage first
            // For now, we'll use placeholder URLs
            let imageURLs = selectedImageData.enumerated().map { index, _ in
                "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=800&h=600&fit=crop&auto=format&q=60&ixid=M3wxMjA3fDB8MHxzZWFyY2h8\(index + 1)fHxob3VzZXxlbnwwfHwwfHx8MA%3D%3D"
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
