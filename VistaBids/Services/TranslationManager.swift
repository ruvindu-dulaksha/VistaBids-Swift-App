import Foundation
import SwiftUI

/// Centralized translation manager to handle all translation functionality in the app
class TranslationManager: ObservableObject {
    // Singleton instance for shared access
    static let shared = TranslationManager()
    
    // Published properties for UI updates
    @Published var selectedLanguage: String = Locale.current.languageCode ?? "en"
    @Published var isTranslating: Bool = false
    @Published var isTranslated: Bool = false
    @Published var targetLanguage: String = ""
    @Published var error: String?
    
    private let translationService = AppleTranslationService()
    
    // List of supported languages with display name, flag, and native name
    let supportedLanguages: [(code: String, display: String, flag: String, nativeName: String)] = [
        ("en", "English", "🇺🇸", "English"),
        ("es", "Spanish", "🇪🇸", "Español"),
        ("fr", "French", "🇫🇷", "Français"),
        ("de", "German", "🇩🇪", "Deutsch"),
        ("ja", "Japanese", "🇯🇵", "日本語"),
        ("zh", "Chinese", "🇨🇳", "中文")
    ]
    
    init() {
        // Default to user's locale language if supported, otherwise English
        let userLanguage = Locale.current.languageCode ?? "en"
        if supportedLanguages.contains(where: { $0.code == userLanguage }) {
            selectedLanguage = userLanguage
        } else {
            selectedLanguage = "en"
        }
    }
    
    /// The display name of the currently selected language
    var targetLanguageDisplayName: String {
        return languageDisplayName(for: targetLanguage.isEmpty ? selectedLanguage : targetLanguage)
    }
    
    /// Translates text to the currently selected language
    /// - Parameter text: The text to translate
    /// - Parameter sourceLanguage: The source language code (if known)
    /// - Returns: The translated text
    func translateText(_ text: String, from sourceLanguage: String) async throws -> String {
        isTranslating = true
        defer { isTranslating = false }
        
        do {
            // Skip translation if source and target language are the same
            if sourceLanguage == selectedLanguage {
                return text
            }
            
            let translatedText = try await translationService.translateText(text, to: selectedLanguage)
            
            // Update state on successful translation
            DispatchQueue.main.async {
                self.isTranslated = true
                self.targetLanguage = self.selectedLanguage
            }
            
            return translatedText
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Translates a CommunityPost to the currently selected language
    /// - Parameter post: The post to translate
    /// - Returns: The translated post
    func translatePost(_ post: CommunityPost) async -> CommunityPost {
        isTranslating = true
        defer { isTranslating = false }
        
        var updatedPost = post
        
        // Skip translation if target language is the same as original
        if post.originalLanguage == selectedLanguage {
            updatedPost.translatedContent = nil
            updatedPost.isTranslated = false
            return updatedPost
        }
        
        do {
            let translatedContent = try await translationService.translateText(post.content, to: selectedLanguage)
            updatedPost.translatedContent = translatedContent
            updatedPost.isTranslated = true
            updatedPost.translatedLanguage = selectedLanguage
            
            // Update state on successful translation
            DispatchQueue.main.async {
                self.isTranslated = true
                self.targetLanguage = self.selectedLanguage
            }
        } catch {
            // On error, clear any existing translation and show original
            updatedPost.translatedContent = nil
            updatedPost.isTranslated = false
            updatedPost.translatedLanguage = nil
            
            DispatchQueue.main.async {
                self.error = "Translation failed: \(error.localizedDescription)"
            }
        }
        
        return updatedPost
    }
    
    /// Translates a ChatMessage to the currently selected language
    /// - Parameter message: The message to translate
    /// - Returns: The translated message
    func translateMessage(_ message: ChatMessage) async -> ChatMessage {
        isTranslating = true
        defer { isTranslating = false }
        
        var updatedMessage = message
        
        // Skip translation if target language is the same as original
        if message.originalLanguage == selectedLanguage {
            updatedMessage.translatedContent = nil
            return updatedMessage
        }
        
        do {
            let translatedContent = try await translationService.translateText(message.content, to: selectedLanguage)
            updatedMessage.translatedContent = translatedContent
            
            // Update state on successful translation
            DispatchQueue.main.async {
                self.isTranslated = true
                self.targetLanguage = self.selectedLanguage
            }
        } catch {
            // On error, clear any existing translation
            updatedMessage.translatedContent = nil
            
            DispatchQueue.main.async {
                self.error = "Translation failed: \(error.localizedDescription)"
            }
        }
        
        return updatedMessage
    }
    
    /// Translates a property listing
    /// - Parameter property: The property to translate
    /// - Returns: The translated property wrapped in a TranslatableProperty
    func translateProperty(_ property: Property, from sourceLanguage: String = "en") async -> TranslatableProperty {
        isTranslating = true
        defer { isTranslating = false }
        
        var translatableProperty = TranslatableProperty(property: property, originalLanguage: sourceLanguage)
        
        // Skip translation if already in target language
        if sourceLanguage == selectedLanguage {
            return translatableProperty
        }
        
        do {
            // Translate title and description in parallel for efficiency
            async let translatedTitle = translationService.translateText(property.title, to: selectedLanguage)
            async let translatedDescription = translationService.translateText(property.description, to: selectedLanguage)
            
            // Wait for both translations to complete
            let title = try await translatedTitle
            let description = try await translatedDescription
            
            // Update translatable property with translations
            translatableProperty = translatableProperty.withTranslations(
                title: title,
                description: description,
                language: selectedLanguage
            )
            
            // Update state on successful translation
            DispatchQueue.main.async {
                self.isTranslated = true
                self.targetLanguage = self.selectedLanguage
            }
        } catch {
            // On error, clear any existing translations
            translatableProperty = translatableProperty.resetTranslation()
            
            DispatchQueue.main.async {
                self.error = "Translation failed: \(error.localizedDescription)"
            }
        }
        
        return translatableProperty
    }
    
    /// Reset translation state back to original
    func resetTranslation() {
        DispatchQueue.main.async {
            self.isTranslated = false
            self.targetLanguage = ""
            self.error = nil
        }
    }
    
    /// Gets the display name for a language code
    /// - Parameter code: The language code
    /// - Returns: The display name
    func languageDisplayName(for code: String) -> String {
        return supportedLanguages.first { $0.code == code }?.display ?? "Unknown"
    }
    
    /// Gets the flag emoji for a language code
    /// - Parameter code: The language code
    /// - Returns: The flag emoji
    func languageFlag(for code: String) -> String {
        return supportedLanguages.first { $0.code == code }?.flag ?? "🏳️"
    }
    
    /// Gets the native name for a language code
    /// - Parameter code: The language code
    /// - Returns: The native name
    func languageNativeName(for code: String) -> String {
        return supportedLanguages.first { $0.code == code }?.nativeName ?? "Unknown"
    }
    
    /// Gets the formatted display text for a language code (flag + code)
    /// - Parameter code: The language code
    /// - Returns: The formatted display text
    func languageDisplay(for code: String) -> String {
        let flag = languageFlag(for: code)
        return "\(flag) \(code.uppercased())"
    }
}
