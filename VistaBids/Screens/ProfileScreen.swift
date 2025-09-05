//
//  ProfileScreen.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-08.
//

import SwiftUI
import FirebaseFirestore

struct ProfileScreen: View {
    @EnvironmentObject private var authService: FirebaseAuthService
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var userStatsService = UserStatsService.shared
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingLogoutAlert = false
    @State private var showingMyProperties = false
    @State private var showingFavorites = false
    @State private var showingTransactionHistory = false
    @State private var showingSavedCards = false
    @State private var showingNotifications = false
    @State private var showingHelpSupport = false
    @State private var extendedProfile = ExtendedUserProfile()
    @State private var isLoadingProfile = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    ProfileImageView(imageURL: extendedProfile.photoURL.isEmpty ? (authService.currentUser?.photoURL?.absoluteString ?? "") : extendedProfile.photoURL,
                                   displayName: extendedProfile.displayName.isEmpty ? (authService.currentUser?.displayName ?? "U") : extendedProfile.displayName)
                    
                    VStack(spacing: 8) {
                        Text(extendedProfile.displayName.isEmpty ? (authService.currentUser?.displayName ?? "User") : extendedProfile.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(authService.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if !extendedProfile.location.isEmpty {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.accentBlues)
                                    .font(.caption)
                                Text(extendedProfile.location)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !extendedProfile.phoneNumber.isEmpty {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.accentBlues)
                                    .font(.caption)
                                Text(extendedProfile.phoneNumber)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !extendedProfile.bio.isEmpty {
                            Text(extendedProfile.bio)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        // Profile Completeness
                        if extendedProfile.profileCompleteness < 100 {
                            VStack(spacing: 4) {
                                HStack {
                                    Text("Profile Completeness")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(extendedProfile.profileCompleteness)%")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.accentBlues)
                                }
                                
                                ProgressView(value: Double(extendedProfile.profileCompleteness), total: 100)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(height: 4)
                                    .scaleEffect(x: 1, y: 1, anchor: .center)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        if let isEmailVerified = authService.currentUser?.isEmailVerified {
                            HStack {
                                Image(systemName: isEmailVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(isEmailVerified ? .green : .orange)
                                Text(isEmailVerified ? "Verified" : "Unverified")
                                    .font(.caption)
                                    .foregroundColor(isEmailVerified ? .green : .orange)
                            }
                        }
                    }
                    
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        Text("Edit Profile")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.accentBlues)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentBlues, lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 20)
                
                // Stats Section
                HStack(spacing: 0) {
                    VStack {
                        Text("\(userStatsService.userStats.propertiesSold)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Properties\nSold")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 40)
                    
                    VStack {
                        Text("\(userStatsService.userStats.activeBids)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Active\nBids")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 40)
                    
                    VStack {
                        Text("\(userStatsService.userStats.watchlistItems)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Watchlist\nItems")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Menu Items
                VStack(spacing: 0) {
                    ProfileMenuItem(icon: "house.fill", title: "My Properties", subtitle: "Manage your listings") {
                        showingMyProperties = true
                    }
                    Divider().padding(.leading, 60)
                    
                    ProfileMenuItem(icon: "heart.fill", title: "Favorites", subtitle: "Your saved properties") {
                        showingFavorites = true
                    }
                    Divider().padding(.leading, 60)
                    
                    ProfileMenuItem(icon: "doc.text.fill", title: "Transaction History", subtitle: "View past transactions") {
                        showingTransactionHistory = true
                    }
                    Divider().padding(.leading, 60)
                    
                    ProfileMenuItem(icon: "creditcard.fill", title: "Saved Cards", subtitle: "Manage payment methods") {
                        showingSavedCards = true
                    }
                    Divider().padding(.leading, 60)
                    
                    ProfileMenuItem(icon: "bell.fill", title: "Notifications", subtitle: "Manage notifications") {
                        showingNotifications = true
                    }
                    Divider().padding(.leading, 60)
                    
                    ProfileMenuItem(icon: "gearshape.fill", title: "Settings", subtitle: "App preferences") {
                        showingSettings = true
                    }
                    Divider().padding(.leading, 60)
                    
                    ProfileMenuItem(icon: "questionmark.circle.fill", title: "Help & Support", subtitle: "Get help") {
                        showingHelpSupport = true
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Logout Button
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(Color.backgrounds)
        .sheet(isPresented: $showingEditProfile, onDismiss: {
            // Refresh profile when edit sheet is dismissed
            loadExtendedProfile()
        }) {
            ProfileEditView(extendedProfile: $extendedProfile)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingSettings) {
            ProfileSettingsView()
                .environmentObject(themeManager)
                .environmentObject(authService)
        }
        .fullScreenCover(isPresented: $showingMyProperties) {
            MyPropertiesView()
                .environmentObject(userStatsService)
        }
        .fullScreenCover(isPresented: $showingFavorites) {
            FavoritesView()
                .environmentObject(userStatsService)
        }
        .fullScreenCover(isPresented: $showingTransactionHistory) {
            TransactionHistoryView()
                .environmentObject(userStatsService)
        }
        .fullScreenCover(isPresented: $showingSavedCards) {
            SavedCardsView()
                .environmentObject(authService)
        }
        .fullScreenCover(isPresented: $showingNotifications) {
            NotificationView()
        }
        .fullScreenCover(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task {
                    do {
                        try authService.signOut()
                    } catch {
                        print("Sign out error: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onAppear {
            userStatsService.loadUserStats()
            loadExtendedProfile()
        }
    }
    
    private func loadExtendedProfile() {
        isLoadingProfile = true
        Task {
            do {
                let profile = try await userStatsService.loadExtendedProfile()
                await MainActor.run {
                    extendedProfile = profile
                    isLoadingProfile = false
                }
            } catch {
                await MainActor.run {
                    isLoadingProfile = false
                    print("Failed to load extended profile: \(error)")
                }
            }
        }
    }
}

// MARK: - Profile Menu Item
struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentBlues)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile View
struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: FirebaseAuthService
    @StateObject private var userStatsService = UserStatsService.shared
    @Binding var extendedProfile: ExtendedUserProfile  // Add binding to parent's profile
    @State private var displayName = ""
    @State private var photoURL = ""
    @State private var phoneNumber = ""
    @State private var location = ""
    @State private var bio = ""
    @State private var isLoading = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var errorMessage: String?
    @State private var showingSuccessAlert = false
    @State private var showingActionSheet = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Photo Section
                    VStack(spacing: 16) {
                        Button(action: {
                            showingActionSheet = true
                        }) {
                            ZStack {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.accentBlues, lineWidth: 3)
                                        )
                                } else {
                                    ProfileImageView(imageURL: photoURL, displayName: displayName.isEmpty ? "U" : displayName)
                                        .scaleEffect(1.2) // Make it slightly larger in edit mode
                                }
                            }
                        }
                        
                        Text("Tap to change photo")
                            .font(.caption)
                            .foregroundColor(.accentBlues)
                    }
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        ProfileTextField(
                            title: "Display Name",
                            text: $displayName,
                            placeholder: "Enter your name",
                            isRequired: true
                        )
                        
                        ProfileTextField(
                            title: "Phone Number",
                            text: $phoneNumber,
                            placeholder: "Enter your phone number",
                            keyboardType: .phonePad
                        )
                        
                        ProfileTextField(
                            title: "Location",
                            text: $location,
                            placeholder: "City, State/Country"
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Bio")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(bio.count)/150")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            TextEditor(text: $bio)
                                .frame(height: 80)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .onChange(of: bio) { _, newValue in
                                    if newValue.count > 150 {
                                        bio = String(newValue.prefix(150))
                                    }
                                }
                        }
                        
                        // Photo URL Field (Advanced)
                        DisclosureGroup("Advanced Options") {
                            VStack(spacing: 16) {
                                ProfileTextField(
                                    title: "Photo URL",
                                    text: $photoURL,
                                    placeholder: "Enter photo URL",
                                    keyboardType: .URL
                                )
                            }
                            .padding(.top, 12)
                        }
                        
                        // Current Email (Read Only)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .fontWeight(.medium)
                            HStack {
                                Text(authService.currentUser?.email ?? "")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Cannot be changed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
            .confirmationDialog("Change Profile Photo", isPresented: $showingActionSheet) {
                Button("Take Photo") {
                    showingCamera = true
                }
                Button("Choose from Library") {
                    showingPhotoLibrary = true
                }
                if selectedImage != nil || !photoURL.isEmpty {
                    Button("Remove Photo", role: .destructive) {
                        selectedImage = nil
                        photoURL = ""
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera) { image in
                    selectedImage = image
                }
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                ImagePicker(sourceType: .photoLibrary) { image in
                    selectedImage = image
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                                Text("Updating Profile...")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                            .padding(24)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(12)
                        )
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
        .alert("Profile Updated", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been updated successfully.")
        }
    }
    
    private func loadCurrentProfile() {
        // Initialize with binding data if available
        displayName = extendedProfile.displayName.isEmpty ? (authService.currentUser?.displayName ?? "") : extendedProfile.displayName
        phoneNumber = extendedProfile.phoneNumber
        location = extendedProfile.location
        bio = extendedProfile.bio
        
        // Handle photoURL migration from old format to new format
        let currentPhotoURL = extendedProfile.photoURL.isEmpty ? (authService.currentUser?.photoURL?.absoluteString ?? "") : extendedProfile.photoURL
        
        // Check if we need to migrate from old file:// format to new local:// format
        if currentPhotoURL.hasPrefix("file://") {
            // Try to extract filename and convert to new format
            if let url = URL(string: currentPhotoURL) {
                let filename = url.lastPathComponent
                photoURL = "local://images/\(filename)"
                print("🔄 Migrated profile image URL from file:// to local:// format")
            } else {
                photoURL = currentPhotoURL
            }
        } else {
            photoURL = currentPhotoURL
        }
    }
    
    private func saveProfile() {
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedDisplayName.isEmpty else {
            errorMessage = "Display name is required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var finalPhotoURL = photoURL.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Upload image if user selected one
                if let selectedImage = selectedImage {
                    finalPhotoURL = try await uploadProfileImage(selectedImage)
                }
                
                // Update Firebase Auth profile
                try await userStatsService.updateUserProfile(
                    displayName: trimmedDisplayName,
                    photoURL: finalPhotoURL.isEmpty ? nil : finalPhotoURL
                )
                
                // Update extended profile data in Firestore
                try await userStatsService.updateExtendedProfile(
                    displayName: trimmedDisplayName,
                    photoURL: finalPhotoURL,
                    phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                    location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                    bio: bio.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                // Update the binding to refresh parent view
                let updatedProfile = ExtendedUserProfile(
                    displayName: trimmedDisplayName,
                    photoURL: finalPhotoURL,
                    phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                    location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                    bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
                    profileCompleteness: userStatsService.calculateProfileCompleteness(
                        displayName: trimmedDisplayName,
                        photoURL: finalPhotoURL,
                        phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                        location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                        bio: bio.trimmingCharacters(in: .whitespacesAndNewlines)
                    ),
                    lastUpdated: Timestamp()
                )
                
                await MainActor.run {
                    extendedProfile = updatedProfile  // Update the binding
                    isLoading = false
                    showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to update profile: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let userId = authService.currentUser?.uid else {
            throw ProfileError.imageProcessingFailed
        }
        
        // Use ImageUtils for consistent image storage
        let filename = "profile_\(userId).jpg"
        
        do {
            let localURL = try ImageUtils.shared.saveImageLocally(image, filename: filename)
            print("✅ Profile image saved successfully: \(localURL)")
            return localURL
        } catch {
            print("❌ Failed to save profile image: \(error)")
            throw ProfileError.uploadFailed
        }
    }
}

// MARK: - Profile Text Field
struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isRequired: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
        }
    }
}

// MARK: - Profile Errors
enum ProfileError: LocalizedError {
    case notAuthenticated
    case imageProcessingFailed
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .uploadFailed:
            return "Failed to upload image"
        }
    }
}

// MARK: - Settings View
struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject private var authService: FirebaseAuthService
    @EnvironmentObject private var appLockService: AppLockService
    @StateObject private var biometricAuthService = BiometricAuthService()
    @StateObject private var biometricCredentialsService = BiometricCredentialsService()
    @StateObject private var userStatsService = UserStatsService.shared
    @State private var notificationSettings = UserNotificationSettings()
    @State private var showingBiometricAlert = false
    @State private var biometricAlertMessage = ""
    @State private var showingDisableBiometricAlert = false
    @State private var isLoadingNotifications = false
    
    private var biometricStatusText: some View {
        if !biometricAuthService.isBiometricAvailable {
            Text("Not available on this device")
                .font(.caption)
                .foregroundColor(.secondary)
        } else if !biometricCredentialsService.isBiometricLoginEnabled {
            Text("Enable for quick login & app security")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            Text("Enabled - Quick login & app lock active")
                .font(.caption)
                .foregroundColor(.green)
        }
    }
    
    private var biometricToggleBinding: Binding<Bool> {
        Binding(
            get: { biometricCredentialsService.isBiometricLoginEnabled },
            set: { isEnabled in
                if isEnabled {
                    enableFaceIDAppLock()
                } else {
                    showingDisableBiometricAlert = true
                }
            }
        )
    }
    
    private var notificationsSection: some View {
        Section("Notifications") {
            NotificationToggleRow(
                icon: "bell.fill",
                title: "Push Notifications",
                isEnabled: $notificationSettings.pushNotifications
            )
            
            NotificationToggleRow(
                icon: "gavel.fill",
                title: "Bidding Updates",
                isEnabled: $notificationSettings.bidOutbid
            )
            
            NotificationToggleRow(
                icon: "message.fill",
                title: "Email Notifications",
                isEnabled: $notificationSettings.emailNotifications
            )
            
            NotificationToggleRow(
                icon: "dollarsign.circle.fill",
                title: "Price Drops",
                isEnabled: $notificationSettings.priceDrops
            )
            
            NotificationToggleRow(
                icon: "newspaper.fill",
                title: "Market Updates",
                isEnabled: $notificationSettings.marketUpdates
            )
        }
    }
    
    private var securitySectionFooter: some View {
        Group {
            if biometricAuthService.isBiometricAvailable && !biometricCredentialsService.isBiometricLoginEnabled {
                Text("When enabled, you can use \(biometricAuthService.biometricDisplayName) to sign in quickly without entering your password. The app will also lock when closed for security.")
            } else if !biometricAuthService.isBiometricAvailable {
                Text("Biometric authentication is not available on this device or not set up in system settings.")
            } else {
                Text("\(biometricAuthService.biometricDisplayName) is enabled for quick login and app security. The app locks when closed and you can sign in with \(biometricAuthService.biometricDisplayName).")
            }
        }
    }
    
    private var securitySection: some View {
        Section {
            HStack {
                Image(systemName: biometricAuthService.biometricIcon)
                    .foregroundColor(.accentBlues)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(biometricAuthService.biometricDisplayName)
                        .foregroundColor(.textPrimary)
                    biometricStatusText
                }
                
                Spacer()
                
                Toggle("", isOn: biometricToggleBinding)
                    .disabled(!biometricAuthService.isBiometricAvailable)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Security")
        } footer: {
            securitySectionFooter
        }
    }
    
    private var appearanceSection: some View {
        Section("Appearance") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.headline)
                ForEach(ThemeMode.allCases, id: \.self) { theme in
                    themeRow(for: theme)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func themeRow(for theme: ThemeMode) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                themeManager.currentTheme = theme
            }
        }) {
            HStack {
                Image(systemName: theme.icon)
                    .foregroundColor(.accentBlues)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .foregroundColor(.textPrimary)
                    if theme == .system {
                        Text("Follow system settings")
                            .font(.caption)
                            .foregroundColor(.secondaryTextColor)
                    }
                }
                Spacer()
                if themeManager.currentTheme == theme {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentBlues)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        NavigationView {
            Form {
                notificationsSection
                securitySection
                appearanceSection
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondaryTextColor)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.accentBlues)
                }
            }
            .onAppear {
                loadNotificationSettings()
            }
            .onChange(of: notificationSettings.pushNotifications) { 
                saveNotificationSettings() 
            }
            .onChange(of: notificationSettings.bidOutbid) { 
                saveNotificationSettings() 
            }
            .onChange(of: notificationSettings.emailNotifications) { 
                saveNotificationSettings() 
            }
            .onChange(of: notificationSettings.priceDrops) { 
                saveNotificationSettings() 
            }
            .onChange(of: notificationSettings.marketUpdates) { 
                saveNotificationSettings() 
            }
        }
        .alert("Biometric Authentication", isPresented: $showingBiometricAlert) {
            Button("OK") { }
        } message: {
            Text(biometricAlertMessage)
        }
        .alert("Disable Biometric Login", isPresented: $showingDisableBiometricAlert) {
            Button("Disable", role: .destructive) {
                disableBiometricLogin()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to disable \(biometricAuthService.biometricDisplayName)? You'll need to enter your email and password to sign in, and the app will no longer lock automatically.")
        }
    }
    
    private func enableFaceIDAppLock() {
        Task {
            do {
                // Test Face ID authentication to ensure it works
                let success = try await biometricAuthService.authenticateWithBiometrics()
                
                if success {
                    await MainActor.run {
                        // Simply enable Face ID app lock
                        biometricCredentialsService.isBiometricLoginEnabled = true
                        
                        biometricAlertMessage = """
                        \(biometricAuthService.biometricDisplayName) Enabled Successfully!
                        
                        Security features now active:
                        • App will lock when closed or backgrounded
                        • Use \(biometricAuthService.biometricDisplayName) to unlock
                        • Enhanced app security
                        
                        Note: For quick login with \(biometricAuthService.biometricDisplayName), you'll need to sign out and sign back in to store your credentials securely.
                        """
                        showingBiometricAlert = true
                    }
                } else {
                    await MainActor.run {
                        biometricAlertMessage = "\(biometricAuthService.biometricDisplayName) authentication failed. Please try again."
                        showingBiometricAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    if let biometricError = error as? BiometricError {
                        switch biometricError {
                        case .userCancelled:
                            // Don't show error for user cancellation
                            return
                        case .notEnrolled:
                            biometricAlertMessage = "\(biometricAuthService.biometricDisplayName) is not set up on this device. Please set it up in Settings app first."
                        case .notAvailable:
                            biometricAlertMessage = "\(biometricAuthService.biometricDisplayName) is not available on this device."
                        case .lockout:
                            biometricAlertMessage = "\(biometricAuthService.biometricDisplayName) is currently locked. Please unlock it using your device passcode first."
                        case .missingPrivacyPermission:
                            biometricAlertMessage = "Face ID access not granted. Please allow Face ID access in app settings to use this feature."
                        default:
                            biometricAlertMessage = biometricError.localizedDescription
                        }
                    } else {
                        biometricAlertMessage = "Failed to enable \(biometricAuthService.biometricDisplayName): \(error.localizedDescription)"
                    }
                    showingBiometricAlert = true
                }
            }
        }
    }
    
    private func disableBiometricLogin() {
        // Clear stored credentials
        biometricCredentialsService.clearStoredCredentials()
        
        // Disable Face ID app lock
        appLockService.disableFaceIDAppLock()
        
        biometricAlertMessage = "\(biometricAuthService.biometricDisplayName) has been disabled for both quick login and app security."
        showingBiometricAlert = true
    }
    
    private func loadNotificationSettings() {
        isLoadingNotifications = true
        Task {
            if let settings = await userStatsService.getNotificationSettings() {
                await MainActor.run {
                    notificationSettings = settings
                    isLoadingNotifications = false
                }
            } else {
                await MainActor.run {
                    isLoadingNotifications = false
                }
            }
        }
    }
    
    private func saveNotificationSettings() {
        Task {
            await userStatsService.updateNotificationSettings(notificationSettings)
        }
    }
}

// MARK: - Notification Toggle Row
struct NotificationToggleRow: View {
    let icon: String
    let title: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(Color("PrimaryTextColor"))
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Profile Image View
struct ProfileImageView: View {
    let imageURL: String
    let displayName: String
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let loadedImage = loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                placeholderImage
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    )
            } else {
                placeholderImage
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.cardBackground, lineWidth: 4)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            loadImageIfNeeded()
        }
        .onChange(of: imageURL) { _, _ in
            loadImageIfNeeded()
        }
    }
    
    private var placeholderImage: some View {
        Circle()
            .fill(Color.accentBlues.opacity(0.2))
            .overlay(
                Text(displayName.prefix(1).uppercased())
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentBlues)
            )
    }
    
    private func loadImageIfNeeded() {
        guard !imageURL.isEmpty, loadedImage == nil else { return }
        
        isLoading = true
        
        Task {
            let image = await loadImage(from: imageURL)
            await MainActor.run {
                loadedImage = image
                isLoading = false
            }
        }
    }
    
    private func loadImage(from urlString: String) async -> UIImage? {
        if urlString.hasPrefix("local://") {
            // Load from local storage using ImageUtils
            return await ImageUtils.shared.loadImage(from: urlString)
        } else if urlString.hasPrefix("file://") {
            // Handle legacy file:// URLs
            guard let url = URL(string: urlString),
                  let imageData = try? Data(contentsOf: url) else {
                return nil
            }
            return UIImage(data: imageData)
        } else if !urlString.isEmpty {
            // Load remote image
            guard let url = URL(string: urlString) else { return nil }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                return UIImage(data: data)
            } catch {
                print("Failed to load remote image: \(error)")
                return nil
            }
        }
        return nil
    }
}

// MARK: - Saved Cards View
struct SavedCardsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: FirebaseAuthService
    @StateObject private var cardsService = SavedCardsService.shared
    @State private var showingAddCard = false
    @State private var showingDeleteAlert = false
    @State private var cardToDelete: SavedCard?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Saved Payment Methods")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Manage your saved cards for faster checkout")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                if cardsService.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading cards...")
                        Spacer()
                    }
                } else if cardsService.savedCards.isEmpty {
                    // Empty State
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "creditcard")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 8) {
                            Text("No Saved Cards")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Add a payment method to make bidding faster and easier")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            showingAddCard = true
                        }) {
                            Text("Add Your First Card")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentBlues)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                } else {
                    // Cards List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(cardsService.savedCards) { card in
                                SavedCardRow(card: card,
                                           onDelete: { confirmDelete(card) },
                                           onSetDefault: { setDefault(card) })
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Add Card Button
                    VStack {
                        Button(action: {
                            showingAddCard = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add New Card")
                            }
                            .font(.headline)
                            .foregroundColor(.accentBlues)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentBlues, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            cardsService.loadSavedCards()
        }
        .onDisappear {
            cardsService.stopListening()
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardView { newCard in
                Task {
                    do {
                        try await cardsService.addCard(newCard)
                        errorMessage = nil
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .alert("Delete Card", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let card = cardToDelete {
                    deleteCard(card)
                }
            }
        } message: {
            if let card = cardToDelete {
                Text("Are you sure you want to delete the card ending in \(card.lastFourDigits)?")
            }
        }
    }
    
    private func confirmDelete(_ card: SavedCard) {
        cardToDelete = card
        showingDeleteAlert = true
    }
    
    private func deleteCard(_ card: SavedCard) {
        Task {
            do {
                try await cardsService.removeCard(card)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func setDefault(_ card: SavedCard) {
        guard !card.isDefault else { return }
        
        Task {
            do {
                try await cardsService.setDefaultCard(card)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Saved Cards Service
class SavedCardsService: ObservableObject {
    static let shared = SavedCardsService()
    
    @Published var savedCards: [SavedCard] = []
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let cardsKey = "saved_cards"
    
    private init() {}
    
    // MARK: - Load Cards
    func loadSavedCards() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadCardsFromStorage()
            self.isLoading = false
        }
    }
    
    private func loadCardsFromStorage() {
        guard let data = userDefaults.data(forKey: cardsKey) else {
            savedCards = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            savedCards = try decoder.decode([SavedCard].self, from: data)
            print("Loaded \(savedCards.count) saved cards from storage")
        } catch {
            print("Error loading saved cards: \(error.localizedDescription)")
            savedCards = []
        }
    }
    
    // MARK: - Add Card
    func addCard(_ card: SavedCard) async throws {
        // If this is set as default, remove default from other cards first
        if card.isDefault {
            await clearDefaultCards()
        }
        
        await MainActor.run {
            savedCards.append(card)
            saveCardsToStorage()
        }
        
        print("Successfully added card: \(card.maskedNumber)")
    }
    
    // MARK: - Remove Card
    func removeCard(_ card: SavedCard) async throws {
        await MainActor.run {
            savedCards.removeAll { $0.id == card.id }
            saveCardsToStorage()
        }
        
        print("Successfully removed card: \(card.maskedNumber)")
    }
    
    // MARK: - Set Default Card
    func setDefaultCard(_ card: SavedCard) async throws {
        await clearDefaultCards()
        
        await MainActor.run {
            if let index = savedCards.firstIndex(where: { $0.id == card.id }) {
                let updatedCard = SavedCard(
                    id: card.id,
                    lastFourDigits: card.lastFourDigits,
                    cardType: card.cardType,
                    expiryMonth: card.expiryMonth,
                    expiryYear: card.expiryYear,
                    cardholderName: card.cardholderName,
                    isDefault: true
                )
                savedCards[index] = updatedCard
                saveCardsToStorage()
            }
        }
        
        print("Successfully set default card: \(card.maskedNumber)")
    }
    
    // MARK: - Clear Default Cards
    private func clearDefaultCards() async {
        await MainActor.run {
            for index in savedCards.indices {
                if savedCards[index].isDefault {
                    let card = savedCards[index]
                    savedCards[index] = SavedCard(
                        id: card.id,
                        lastFourDigits: card.lastFourDigits,
                        cardType: card.cardType,
                        expiryMonth: card.expiryMonth,
                        expiryYear: card.expiryYear,
                        cardholderName: card.cardholderName,
                        isDefault: false
                    )
                }
            }
            saveCardsToStorage()
        }
    }
    
    // MARK: - Get Default Card
    func getDefaultCard() -> SavedCard? {
        return savedCards.first { $0.isDefault }
    }
    
    // MARK: - Save to Storage
    private func saveCardsToStorage() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(savedCards)
            userDefaults.set(data, forKey: cardsKey)
            print("Successfully saved \(savedCards.count) cards to storage")
        } catch {
            print("Error saving cards: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Stop Listening
    func stopListening() {
        // For UserDefaults implementation, no listening to stop
    }
}

// MARK: - Saved Card Model
struct SavedCard: Identifiable, Codable {
    var id = UUID()
    let lastFourDigits: String
    let cardType: String
    let expiryMonth: Int
    let expiryYear: Int
    let cardholderName: String
    let isDefault: Bool
    let createdAt: Date
    
    init(id: UUID = UUID(), lastFourDigits: String, cardType: String, expiryMonth: Int, expiryYear: Int, cardholderName: String, isDefault: Bool = false) {
        self.id = id
        self.lastFourDigits = lastFourDigits
        self.cardType = cardType
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.cardholderName = cardholderName
        self.isDefault = isDefault
        self.createdAt = Date()
    }
    
    var maskedNumber: String {
        "**** **** **** \(lastFourDigits)"
    }
    
    var expiryString: String {
        String(format: "%02d/%02d", expiryMonth, expiryYear % 100)
    }
}

// MARK: - Saved Card Row
struct SavedCardRow: View {
    let card: SavedCard
    let onDelete: () -> Void
    let onSetDefault: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Card Icon
            Image(systemName: cardIcon)
                .font(.title2)
                .foregroundColor(.accentBlues)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(card.cardType)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if card.isDefault {
                        Text("DEFAULT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                Text(card.maskedNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Expires \(card.expiryString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(card.cardholderName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                if !card.isDefault {
                    Button(action: onSetDefault) {
                        Text("Set Default")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentBlues)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentBlues.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var cardIcon: String {
        switch card.cardType.lowercased() {
        case "visa":
            return "creditcard"
        case "mastercard":
            return "creditcard.circle"
        case "amex", "american express":
            return "creditcard.trianglebadge.exclamationmark"
        default:
            return "creditcard"
        }
    }
}

// MARK: - Add Card View
struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss
    let onCardAdded: (SavedCard) -> Void
    
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var isDefault = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Preview
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [Color.accentBlues, Color.accentBlues.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(height: 200)
                            .overlay(
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("VISTA BIDS")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white.opacity(0.8))
                                        Spacer()
                                        Image(systemName: "creditcard")
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formattedCardNumber)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .monospaced()
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("CARDHOLDER NAME")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.7))
                                            Text(cardholderName.isEmpty ? "YOUR NAME" : cardholderName.uppercased())
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("EXPIRES")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.7))
                                            Text(expiryDate.isEmpty ? "MM/YY" : expiryDate)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding(20)
                            )
                    }
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Card Number")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            TextField("1234 5678 9012 3456", text: $cardNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .onChange(of: cardNumber) { _, newValue in
                                    cardNumber = formatCardNumber(newValue)
                                }
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expiry Date")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                TextField("MM/YY", text: $expiryDate)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .onChange(of: expiryDate) { _, newValue in
                                        expiryDate = formatExpiryDate(newValue)
                                    }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CVV")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                TextField("123", text: $cvv)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .onChange(of: cvv) { _, newValue in
                                        cvv = String(newValue.prefix(4))
                                    }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cardholder Name")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            TextField("John Doe", text: $cardholderName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.words)
                        }
                        
                        Toggle("Set as default payment method", isOn: $isDefault)
                            .font(.subheadline)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: saveCard) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            Text(isLoading ? "Saving..." : "Save Card")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.accentBlues : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                }
                .padding(20)
            }
            .navigationTitle("Add Payment Method")
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
    
    private var formattedCardNumber: String {
        if cardNumber.isEmpty {
            return "**** **** **** ****"
        }
        return cardNumber
    }
    
    private var isFormValid: Bool {
        !cardNumber.isEmpty &&
        cardNumber.count >= 19 && // "1234 5678 9012 3456"
        !expiryDate.isEmpty &&
        expiryDate.count == 5 && // "MM/YY"
        !cvv.isEmpty &&
        cvv.count >= 3 &&
        !cardholderName.isEmpty
    }
    
    private func formatCardNumber(_ input: String) -> String {
        let digits = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let limited = String(digits.prefix(16))
        var formatted = ""
        
        for (index, character) in limited.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        
        return formatted
    }
    
    private func formatExpiryDate(_ input: String) -> String {
        let digits = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let limited = String(digits.prefix(4))
        
        if limited.count >= 2 {
            let month = String(limited.prefix(2))
            let year = String(limited.dropFirst(2))
            return month + (year.isEmpty ? "" : "/" + year)
        }
        
        return limited
    }
    
    private func saveCard() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let lastFour = String(cardNumber.suffix(4))
            let cardType = detectCardType(cardNumber)
            let monthYear = expiryDate.split(separator: "/")
            
            let newCard = SavedCard(
                lastFourDigits: lastFour,
                cardType: cardType,
                expiryMonth: Int(monthYear[0]) ?? 1,
                expiryYear: 2000 + (Int(monthYear[1]) ?? 24),
                cardholderName: cardholderName,
                isDefault: isDefault
            )
            
            onCardAdded(newCard)
            isLoading = false
            dismiss()
        }
    }
    
    private func detectCardType(_ number: String) -> String {
        let digits = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if digits.hasPrefix("4") {
            return "Visa"
        } else if digits.hasPrefix("5") || digits.hasPrefix("2") {
            return "Mastercard"
        } else if digits.hasPrefix("3") {
            return "American Express"
        } else {
            return "Unknown"
        }
    }
}

#Preview {
    ProfileScreen()
        .environmentObject(FirebaseAuthService())
        .environmentObject(ThemeManager())
}
