import SwiftUI

struct TranslationButton: View {
    @EnvironmentObject var translationManager: TranslationManager
    let sourceLanguage: String
    let contentId: String // Optional identifier for the content being translated
    let isCompact: Bool
    @State private var isTranslated: Bool = false
    
    init(
        sourceLanguage: String, 
        contentId: String = UUID().uuidString,
        isCompact: Bool = false
    ) {
        self.sourceLanguage = sourceLanguage
        self.contentId = contentId
        self.isCompact = isCompact
    }
    
    var body: some View {
        Button(action: {
            // Trigger translation
            if isTranslated {
                // If already translated, reset to original
                translationManager.resetTranslation()
                isTranslated = false
            } else {
                // Otherwise, trigger new translation
                Task {
                    // The actual translation happens in the parent view
                    // We just update the state here
                    isTranslated = true
                    
                    // Haptic feedback for translation start
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
        }) {
            HStack(spacing: 4) {
                if translationManager.isTranslating {
                    ProgressView()
                        .scaleEffect(0.7)
                    
                    if !isCompact {
                        Text("Translating...")
                            .font(.caption)
                    }
                } else if isTranslated || translationManager.isTranslated {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    if !isCompact {
                        Text("Translated")
                            .font(.caption)
                    }
                } else {
                    Image(systemName: "translate")
                    
                    if !isCompact {
                        if sourceLanguage != translationManager.selectedLanguage {
                            Text("Translate")
                                .font(.caption)
                        }
                    }
                }
            }
            .padding(.horizontal, isCompact ? 6 : 8)
            .padding(.vertical, isCompact ? 4 : 6)
            .background(
                (isTranslated || translationManager.isTranslated)
                ? Color.green.opacity(0.1) 
                : Color.accentBlues.opacity(0.1)
            )
            .foregroundColor((isTranslated || translationManager.isTranslated) ? .green : .accentBlues)
            .cornerRadius(8)
        }
        .disabled(translationManager.isTranslating || sourceLanguage == translationManager.selectedLanguage)
        .opacity(sourceLanguage == translationManager.selectedLanguage ? 0 : 1)
        .onAppear {
            // Sync with global translation state on appear
            isTranslated = translationManager.isTranslated
        }
        .onChange(of: translationManager.isTranslated) { _, newValue in
            isTranslated = newValue
        }
    }
}

#Preview {
    Group {
        TranslationButton(sourceLanguage: "es")
            .previewDisplayName("Normal")
        
        TranslationButton(sourceLanguage: "es", isCompact: true)
            .previewDisplayName("Compact")
    }
    .environmentObject(TranslationManager.shared)
}
