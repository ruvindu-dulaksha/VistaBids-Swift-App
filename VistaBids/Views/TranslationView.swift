import SwiftUI

struct TranslationView: View {
    @EnvironmentObject var translationManager: TranslationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedLanguageID: String
    
    init() {
        // Initialize with the current selected language
        _selectedLanguageID = State(initialValue: TranslationManager.shared.selectedLanguage)
    }
    
    var body: some View {
        NavigationView {
            List {
                // Language selection section
                Section {
                    ForEach(translationManager.supportedLanguages, id: \.code) { language in
                        Button(action: {
                            selectedLanguageID = language.code
                            translationManager.selectedLanguage = language.code
                            
                            // Show feedback when language is changed
                            alertMessage = "Language changed to \(language.display)"
                            showingAlert = true
                            
                            // Haptic feedback
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            
                            // Dismiss after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }) {
                            HStack {
                                Text(language.flag)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(language.display)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(language.nativeName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedLanguageID == language.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentBlues)
                                        .imageScale(.large)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                } header: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.accentBlues)
                        Text("Select Language")
                            .font(.headline)
                    }
                    .padding(.bottom, 4)
                }
                
                // Translation status section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: translationManager.isTranslated ? "checkmark.circle.fill" : "clock")
                                .foregroundColor(translationManager.isTranslated ? .green : .orange)
                                .imageScale(.large)
                            
                            Text(translationManager.isTranslated ? "Content is translated" : "Ready to translate")
                                .font(.headline)
                                .foregroundColor(translationManager.isTranslated ? .green : .orange)
                        }
                        
                        if translationManager.isTranslated {
                            Text("Content is currently displayed in \(translationManager.targetLanguageDisplayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Tap the Translate button on content to translate it")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if translationManager.isTranslated {
                            Button(action: {
                                translationManager.resetTranslation()
                                alertMessage = "Translation reset to original language"
                                showingAlert = true
                            }) {
                                Text("Reset to Original")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.accentBlues)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundColor(.accentBlues)
                        Text("Translation Status")
                            .font(.headline)
                    }
                    .padding(.bottom, 4)
                }
                
                // About section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How Translation Works")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("VistaBids automatically translates property listings, descriptions, and community posts to your preferred language.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            TranslationFeatureItem(
                                icon: "house.fill",
                                title: "Properties",
                                description: "Listings & details"
                            )
                            
                            TranslationFeatureItem(
                                icon: "bubble.left.fill",
                                title: "Community",
                                description: "Posts & comments"
                            )
                            
                            TranslationFeatureItem(
                                icon: "doc.text.fill",
                                title: "Documents",
                                description: "Legal & guides"
                            )
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.vertical, 8)
                } header: {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentBlues)
                        Text("About Translation")
                            .font(.headline)
                    }
                    .padding(.bottom, 4)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Language & Translation")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

struct TranslationFeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentBlues)
                .frame(width: 44, height: 44)
                .background(Color.accentBlues.opacity(0.1))
                .cornerRadius(12)
                .padding(.bottom, 4)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TranslationView()
        .environmentObject(TranslationManager.shared)
}
