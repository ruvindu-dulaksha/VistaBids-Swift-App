import SwiftUI

struct AppLanguageSelector: View {
    @EnvironmentObject var translationManager: TranslationManager
    let isCompact: Bool
    
    init(isCompact: Bool = false) {
        self.isCompact = isCompact
    }
    
    var body: some View {
        Menu {
            ForEach(translationManager.supportedLanguages, id: \.code) { language in
                Button(action: {
                    translationManager.selectedLanguage = language.code
                }) {
                    HStack {
                        Text(language.flag)
                        Text(language.display)
                        
                        if translationManager.selectedLanguage == language.code {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                if isCompact {
                    Text(translationManager.languageFlag(for: translationManager.selectedLanguage))
                } else {
                    Text(translationManager.languageDisplay(for: translationManager.selectedLanguage))
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentBlues)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

#Preview {
    Group {
        AppLanguageSelector()
            .previewDisplayName("Normal")
        
        AppLanguageSelector(isCompact: true)
            .previewDisplayName("Compact")
    }
    .environmentObject(TranslationManager.shared)
}
