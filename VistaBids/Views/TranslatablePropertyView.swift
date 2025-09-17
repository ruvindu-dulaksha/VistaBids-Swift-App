//
//  TranslatablePropertyView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-09-10.
//

import SwiftUI

struct TranslatablePropertyView: View {
    @EnvironmentObject var translationManager: TranslationManager
    let property: Property
    let sourceLanguage: String
    
    @State private var translatableProperty: TranslatableProperty?
    @State private var isTranslating = false
    
    init(property: Property, sourceLanguage: String = "en") {
        self.property = property
        self.sourceLanguage = sourceLanguage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(translatableProperty?.displayTitle ?? property.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Description
            Text(translatableProperty?.displayDescription ?? property.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Translation button
            HStack {
                Spacer()
                
                if isTranslating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, 4)
                    Text("Translating...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Button(action: {
                        translateProperty()
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .imageScale(.small)
                            
                            Text(translatableProperty?.isTranslated == true ? "Show Original" : "Translate")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentBlues.opacity(0.1))
                        .foregroundColor(.accentBlues)
                        .cornerRadius(8)
                    }
                    .opacity(sourceLanguage == translationManager.selectedLanguage ? 0 : 1)
                    .disabled(sourceLanguage == translationManager.selectedLanguage)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            // Initialize translatable property
            translatableProperty = TranslatableProperty(property: property, originalLanguage: sourceLanguage)
            
            
            if translationManager.isTranslated && 
               sourceLanguage != translationManager.selectedLanguage &&
               translationManager.targetLanguage == translationManager.selectedLanguage {
                translateProperty()
            }
        }
        .onChange(of: translationManager.isTranslated) { _, isTranslated in
            // Translate or reset when global translation state changes
            if isTranslated && sourceLanguage != translationManager.selectedLanguage {
                translateProperty()
            } else if !isTranslated && translatableProperty?.isTranslated == true {
                resetTranslation()
            }
        }
        .onChange(of: translationManager.selectedLanguage) { _, newLanguage in
            // Re-translate if language changes and translation is enabled
            if translationManager.isTranslated && sourceLanguage != newLanguage {
                translateProperty()
            }
        }
    }
    
    private func translateProperty() {
        
        if isTranslating || sourceLanguage == translationManager.selectedLanguage {
            return
        }
        
        // Toggle between translated and original if already translated
        if translatableProperty?.isTranslated == true {
            resetTranslation()
            return
        }
        
        // Start translation
        isTranslating = true
        
        Task {
            // Translate the property
            let translated = await translationManager.translateProperty(property, from: sourceLanguage)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.translatableProperty = translated
                self.isTranslating = false
            }
        }
    }
    
    private func resetTranslation() {
        translatableProperty = translatableProperty?.resetTranslation()
    }
}

#Preview {
    TranslatablePropertyView(property: Property.example, sourceLanguage: "es")
        .environmentObject(TranslationManager.shared)
        .padding()
        .background(Color.backgrounds)
}
