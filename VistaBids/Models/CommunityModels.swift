//
//  CommunityModels.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-09.
//

import Foundation
// Temporarily commenting out Firebase imports to fix build errors
import FirebaseFirestore


// MARK: - Community Post Model
struct CommunityPost: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let author: String
    let authorAvatar: String?
    let content: String
    let originalLanguage: String
    let timestamp: Date
    var likes: Int
    var comments: Int
    let imageURLs: [String]
    let location: PostLocation?
    let groupId: String?
    var likedBy: [String]
    var isTranslated: Bool = false
    var translatedContent: String?
    var translatedLanguage: String?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, author, authorAvatar, content, originalLanguage
        case timestamp, likes, comments, imageURLs, location, groupId, likedBy
        case isTranslated, translatedContent, translatedLanguage
    }
}

// MARK: - Post Location Model
struct PostLocation: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
}

// MARK: - Community Event Model
struct CommunityEvent: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let title: String
    let description: String
    let originalLanguage: String
    let date: Date
    let location: EventLocation
    var attendees: [String]
    let maxAttendees: Int
    let imageURLs: [String]
    let groupId: String?
    let category: EventCategory
    var isTranslated: Bool = false
    var translatedTitle: String?
    var translatedDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, title, description, originalLanguage, date
        case location, attendees, maxAttendees, imageURLs, groupId, category
        case isTranslated, translatedTitle, translatedDescription
    }
}

// MARK: - Event Location Model
struct EventLocation: Codable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Event Category Enum
enum EventCategory: String, CaseIterable, Codable {
    case workshop = "Workshop"
    case viewing = "Property Viewing"
    case networking = "Networking"
    case auction = "Auction"
    case seminar = "Seminar"
    case consultation = "Consultation"
    case meetup = "Meetup"
}

// MARK: - Community Group Model
struct CommunityGroup: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let originalLanguage: String
    let createdBy: String
    let createdAt: Date
    var members: [String]
    let imageURL: String?
    let isPrivate: Bool
    let requiresApproval: Bool
    let category: GroupCategory
    var isTranslated: Bool = false
    var translatedName: String?
    var translatedDescription: String?
    
    // Computed property for member count
    var memberCount: Int {
        return members.count
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, originalLanguage, createdBy, createdAt
        case members, imageURL, isPrivate, requiresApproval, category
        case isTranslated, translatedName, translatedDescription
    }
}

// MARK: - Group Category Enum
enum GroupCategory: String, CaseIterable, Codable {
    case investors = "Investors"
    case firstTimeBuyers = "First Time Buyers"
    case luxury = "Luxury Properties"
    case commercial = "Commercial"
    case residential = "Residential"
    case rentals = "Rentals"
    case renovations = "Renovations"
    case legal = "Legal"
    case local = "Local Community"
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let senderName: String
    let senderAvatar: String?
    let content: String
    let originalLanguage: String
    let timestamp: Date
    let chatId: String
    let messageType: MessageType
    let imageURLs: [String]
    var isTranslated: Bool = false
    var translatedContent: String?
    
    enum CodingKeys: String, CodingKey {
        case id, senderId, senderName, senderAvatar, content, originalLanguage
        case timestamp, chatId, messageType, imageURLs
        case isTranslated, translatedContent
    }
}

// MARK: - Message Type Enum
enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case location = "location"
    case property = "property"
}

// MARK: - Chat Room Model
struct ChatRoom: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String?
    let participants: [String]
    let createdBy: String
    let createdAt: Date
    let lastMessage: String?
    let lastMessageTime: Date?
    let isGroup: Bool
    let imageURL: String?
    let groupId: String? // For group chats
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, participants, createdBy, createdAt
        case lastMessage, lastMessageTime, isGroup, imageURL, groupId
    }
}

// MARK: - Comment Model
struct PostComment: Identifiable, Codable {
    @DocumentID var id: String?
    let postId: String
    let userId: String
    let author: String
    let authorAvatar: String?
    let content: String
    let originalLanguage: String
    let timestamp: Date
    var likes: Int
    var likedBy: [String]
    var isTranslated: Bool = false
    var translatedContent: String?
    
    enum CodingKeys: String, CodingKey {
        case id, postId, userId, author, authorAvatar, content, originalLanguage
        case timestamp, likes, likedBy, isTranslated, translatedContent
    }
}

// MARK: - Translation Service Protocol
protocol TranslationServiceProtocol {
    func translateText(_ text: String, to targetLanguage: String) async throws -> String
    func detectLanguage(_ text: String) async throws -> String
}

// MARK: - Translation Errors
enum TranslationError: LocalizedError {
    case unsupportedLanguage
    case invalidURL
    case apiError
    case parseError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedLanguage:
            return "This language is not supported for translation"
        case .invalidURL:
            return "Invalid translation service URL"
        case .apiError:
            return "Translation service error"
        case .parseError:
            return "Could not parse translation response"
        case .networkError:
            return "Network error occurred during translation"
        }
    }
}
