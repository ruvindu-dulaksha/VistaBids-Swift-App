//
//  NewPostView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-09.
//

import SwiftUI
import PhotosUI
import CoreLocation
import CoreLocation

struct NewPostViewV2: View {
    let communityService: CommunityService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
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
    
    init(communityService: CommunityService) {
        self.communityService = communityService
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content editor
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        contentEditorView
                        locationView
                        groupView
                        imagesView
                    }
                    .padding(16)
                }
                
                actionButtonsView
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                toolbarLeadingContent
                toolbarTrailingContent
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
                GroupPickerViewV2(selectedGroup: $selectedGroup, groups: communityService.groups)
            }
        }
    }
    
    // View Components
    
    private var contentEditorView: some View {
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
    }
    
    private var locationView: some View {
        Group {
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
        }
    }
    
    private var groupView: some View {
        Group {
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
        }
    }
    
    private var imagesView: some View {
        Group {
            if !selectedImageData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected Images (\(selectedImageData.count)/5)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(selectedImageData.enumerated()), id: \.offset) { index, imageData in
                                imageItemView(index: index, imageData: imageData)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
    }
    
    private func imageItemView(index: Int, imageData: Data) -> some View {
        Group {
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
    
    private var actionButtonsView: some View {
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
    
    private var toolbarLeadingContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
    }
    
    private var toolbarTrailingContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Post") {
                createPost()
            }
            .fontWeight(.semibold)
            .disabled(postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || postContent.count > 500 || isPosting)
        }
    }
    
    // Helper Methods
    
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
    
    private func createPost() {
        isPosting = true
        
        Task {
            
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
}

// Group Picker View
struct GroupPickerViewV2: View {
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
    let service = CommunityService()
    return NewPostViewV2(communityService: service)
}
