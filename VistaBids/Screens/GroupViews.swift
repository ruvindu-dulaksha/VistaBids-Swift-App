//
//  GroupViews.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-09.
//

import SwiftUI

// MARK: - New Group View
struct NewGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var selectedCategory: GroupCategory = .investors
    @State private var isPrivate = false
    @State private var requiresApproval = false
    @State private var isSubmitting = false
    
    let communityService: CommunityService
    
    private let categories: [GroupCategory] = [.investors, .firstTimeBuyers, .commercial, .residential, .rentals, .renovations, .legal]
    
    var isFormValid: Bool {
        !groupName.isEmpty && !groupDescription.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Group Icon Placeholder
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.accentBlues.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.accentBlues)
                        }
                        
                        Text("Tap to add group photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)
                    
                    // Group Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        TextField("Enter group name", text: $groupName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(12)
                            .background(Color.inputFields)
                            .cornerRadius(10)
                    }
                    
                    // Group Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        TextField("Describe your group's purpose", text: $groupDescription, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(12)
                            .background(Color.inputFields)
                            .cornerRadius(10)
                            .lineLimit(3...8)
                    }
                    
                    // Category Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    HStack {
                                        Image(systemName: categoryIcon(for: category))
                                            .font(.title3)
                                        
                                        Text(categoryTitle(for: category))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                    }
                                    .foregroundColor(selectedCategory == category ? .white : .textPrimary)
                                    .padding(12)
                                    .background(selectedCategory == category ? Color.accentBlues : Color.inputFields)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    // Privacy Settings
                    VStack(spacing: 16) {
                        
                        // Private Group Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Private Group")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                
                                Text("Only members can see posts and members")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $isPrivate)
                                .labelsHidden()
                        }
                        .padding(12)
                        .background(Color.inputFields)
                        .cornerRadius(10)
                        
                        // Approval Required Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Require Approval")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                
                                Text("New members need admin approval to join")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $requiresApproval)
                                .labelsHidden()
                        }
                        .padding(12)
                        .background(Color.inputFields)
                        .cornerRadius(10)
                    }
                    
                    Spacer(minLength: 30)
                    
                    // Create Button
                    Button(action: createGroup) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isSubmitting ? "Creating Group..." : "Create Group")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid && !isSubmitting ? Color.accentBlues : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func categoryIcon(for category: GroupCategory) -> String {
        switch category {
        case .investors: return "chart.line.uptrend.xyaxis"
        case .firstTimeBuyers: return "house"
        case .luxury: return "crown.fill"
        case .commercial: return "building.2"
        case .residential: return "house.fill"
        case .rentals: return "key.fill"
        case .renovations: return "hammer.fill"
        case .legal: return "scale.3d"
        case .local: return "location.fill"
        }
    }
    
    private func categoryTitle(for category: GroupCategory) -> String {
        switch category {
        case .investors: return "Investors"
        case .firstTimeBuyers: return "First Time Buyers"
        case .luxury: return "Luxury Properties"
        case .commercial: return "Commercial"
        case .residential: return "Residential"
        case .rentals: return "Rentals"
        case .renovations: return "Renovations"
        case .legal: return "Legal Advice"
        case .local: return "Local Community"
        }
    }
    
    private func createGroup() {
        isSubmitting = true
        
        Task {
            await communityService.createGroup(
                name: groupName,
                description: groupDescription,
                category: selectedCategory,
                isPrivate: isPrivate,
                requiresApproval: requiresApproval
            )
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Group Detail Components

// Group Header Component
struct GroupHeaderView: View {
    let group: CommunityGroup
    let isMember: Bool
    let isJoining: Bool
    let iconProvider: (GroupCategory) -> String
    let titleProvider: (GroupCategory) -> String
    let onMembershipToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Group Image/Icon
            ZStack {
                Circle()
                    .fill(Color.accentBlues.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: iconProvider(group.category))
                    .font(.system(size: 30))
                    .foregroundColor(.accentBlues)
            }
            
            // Group Info
            VStack(spacing: 8) {
                Text(group.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(titleProvider(group.category))
                    .font(.subheadline)
                    .foregroundColor(.accentBlues)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.accentBlues.opacity(0.2))
                    .cornerRadius(12)
                
                HStack {
                    Text("\(group.memberCount) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if group.isPrivate {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Private")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Description
            Text(group.description)
                .font(.body)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            // Join/Leave Button
            Button(action: onMembershipToggle) {
                HStack {
                    if isJoining {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isMember ? "Leave Group" : (group.requiresApproval ? "Request to Join" : "Join Group"))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isMember ? Color.red : Color.accentBlues)
                .cornerRadius(12)
            }
            .disabled(isJoining)
            .padding(.horizontal, 20)
        }
        .padding(.top, 16)
    }
}

// Group Post Item Component
struct GroupPostItemView: View {
    let post: CommunityPost
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(post.author.prefix(1))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text(post.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(post.content)
                .font(.body)
                .foregroundColor(.textPrimary)
                .lineLimit(3)
            
            HStack {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.caption)
                        Text("\(post.likes)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .font(.caption)
                        Text("\(post.comments)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

// Empty Posts Component
struct EmptyPostsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No posts yet")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Be the first to start a conversation!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Group Detail View
struct GroupDetailView: View {
    let group: CommunityGroup
    let communityService: CommunityService
    
    @State private var isMember = false
    @State private var isJoining = false
    @State private var posts: [CommunityPost] = []
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Group Header
                GroupHeaderView(
                    group: group,
                    isMember: isMember,
                    isJoining: isJoining,
                    iconProvider: categoryIcon,
                    titleProvider: categoryTitle,
                    onMembershipToggle: toggleMembership
                )
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Group Posts Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Posts")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        if isMember {
                            Button("New Post") {
                                // Show new post view
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentBlues)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if posts.isEmpty {
                        EmptyPostsView()
                    } else {
                        ForEach(posts) { post in
                            GroupPostItemView(post: post, colorScheme: colorScheme)
                        }
                    }
                }
            }
        }
        .navigationTitle("Group")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkMembershipStatus()
            loadGroupPosts()
        }
    }
    
    private func categoryIcon(for category: GroupCategory) -> String {
        switch category {
        case .investors: return "chart.line.uptrend.xyaxis"
        case .firstTimeBuyers: return "house"
        case .luxury: return "crown.fill"
        case .commercial: return "building.2"
        case .residential: return "house.fill"
        case .rentals: return "key.fill"
        case .renovations: return "hammer.fill"
        case .legal: return "scale.3d"
        case .local: return "location.fill"
        }
    }
    
    private func categoryTitle(for category: GroupCategory) -> String {
        switch category {
        case .investors: return "Investors"
        case .firstTimeBuyers: return "First Time Buyers"
        case .luxury: return "Luxury Properties"
        case .commercial: return "Commercial"
        case .residential: return "Residential"
        case .rentals: return "Rentals"
        case .renovations: return "Renovations"
        case .legal: return "Legal Advice"
        case .local: return "Local Community"
        }
    }
    
    private func checkMembershipStatus() {
        isMember = group.members.contains("user1") // Mock current user
    }
    
    private func loadGroupPosts() {
        // Load posts specific to this group
        Task {
            do {
                posts = try await communityService.getPostsForGroup(groupId: group.id ?? "")
            } catch {
                print("Failed to load group posts: \(error)")
            }
        }
    }
    
    private func toggleMembership() {
        isJoining = true
        
        Task {
            do {
                if isMember {
                    do {
                        try await communityService.leaveGroup(groupId: group.id ?? "")
                    } catch {
                        print("Failed to leave group: \(error)")
                        throw error
                    }
                } else {
                    await communityService.joinGroup(group.id ?? "")
                }
                
                await MainActor.run {
                    isMember.toggle()
                    isJoining = false
                }
            } catch {
                print("Failed to toggle membership: \(error)")
                await MainActor.run {
                    isJoining = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewGroupView(communityService: CommunityService())
    }
}
