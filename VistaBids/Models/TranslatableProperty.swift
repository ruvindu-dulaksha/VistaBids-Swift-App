//
//  TranslatableProperty.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on  2025-09-10.
//

import Foundation

/// A wrapper around a Property that adds translation capabilities
struct TranslatableProperty {
    let property: Property
    let originalLanguage: String
    var translatedTitle: String?
    var translatedDescription: String?
    var isTranslated: Bool
    var translatedLanguage: String?
    
    init(property: Property, originalLanguage: String = "en") {
        self.property = property
        self.originalLanguage = originalLanguage
        self.isTranslated = false
        self.translatedTitle = nil
        self.translatedDescription = nil
        self.translatedLanguage = nil
    }
    
    /// The title to display, either translated or original
    var displayTitle: String {
        isTranslated && translatedTitle != nil ? translatedTitle! : property.title
    }
    
    /// The description to display, either translated or original
    var displayDescription: String {
        isTranslated && translatedDescription != nil ? translatedDescription! : property.description
    }
    
    /// Returns a new instance with updated translation fields
    func withTranslations(title: String?, description: String?, language: String) -> TranslatableProperty {
        var updated = self
        updated.translatedTitle = title
        updated.translatedDescription = description
        updated.translatedLanguage = language
        updated.isTranslated = title != nil && description != nil
        return updated
    }
    
    /// Returns a new instance with translations reset to original
    func resetTranslation() -> TranslatableProperty {
        var updated = self
        updated.translatedTitle = nil
        updated.translatedDescription = nil
        updated.translatedLanguage = nil
        updated.isTranslated = false
        return updated
    }
}
