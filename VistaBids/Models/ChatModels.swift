import Foundation

struct ChatRoom: Identifiable, Codable {
    let id: String?
    let name: String
    let participants: [String]
    let lastMessage: String?
    let lastMessageTime: Date?
    let imageURL: String?
    let isGroup: Bool
    let createdAt: Date
    
    init(id: String? = nil, name: String, participants: [String], lastMessage: String? = nil, 
         lastMessageTime: Date? = nil, imageURL: String? = nil, isGroup: Bool = false) {
        self.id = id
        self.name = name
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.imageURL = imageURL
        self.isGroup = isGroup
        self.createdAt = Date()
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: String?
    let chatRoomId: String
    let senderId: String
    let senderName: String
    let senderAvatar: String?
    let content: String
    var translatedContent: String?
    let originalLanguage: String
    let timestamp: Date
    
    init(id: String? = nil, chatRoomId: String, senderId: String, senderName: String, senderAvatar: String? = nil,
         content: String, translatedContent: String? = nil, originalLanguage: String = "en", timestamp: Date = Date()) {
        self.id = id
        self.chatRoomId = chatRoomId
        self.senderId = senderId
        self.senderName = senderName
        self.senderAvatar = senderAvatar
        self.content = content
        self.translatedContent = translatedContent
        self.originalLanguage = originalLanguage
        self.timestamp = timestamp
    }
}
