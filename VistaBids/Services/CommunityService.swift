//
//  CommunityService.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-09.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Community Service
@MainActor
class CommunityService: ObservableObject {
    private let db = Firestore.firestore()
    private let translationService = AppleTranslationService()
    
    @Published var posts: [CommunityPost] = []
    @Published var events: [CommunityEvent] = []
    @Published var groups: [CommunityGroup] = []
    @Published var chatRooms: [ChatRoom] = []
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        loadSampleData()
    }
    
    // MARK: - Posts
    func loadPosts() async {
        isLoading = true
        do {
            print("🧩 CommunityService: Starting to load posts from Firestore")
            let snapshot = try await db.collection("community_posts")
                .order(by: "timestamp", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            print("🧩 CommunityService: Received \(snapshot.documents.count) posts from Firestore")
            
            var fetchedPosts: [CommunityPost] = []
            
            for document in snapshot.documents {
                do {
                    if let post = try? document.data(as: CommunityPost.self) {
                        fetchedPosts.append(post)
                        print("🧩 CommunityService: Successfully decoded post: \(post.id ?? "unknown")")
                    } else {
                        print("🧩 CommunityService: Failed to decode post document: \(document.documentID)")
                    }
                } catch {
                    print("🧩 CommunityService: Error decoding post: \(error.localizedDescription)")
                }
            }
            
            if fetchedPosts.isEmpty {
                print("🧩 CommunityService: No posts fetched from Firestore, falling back to sample data")
                // If no posts are fetched, use sample data
                posts = createSamplePosts()
            } else {
                posts = fetchedPosts
                print("🧩 CommunityService: Successfully loaded \(posts.count) posts")
            }
        } catch {
            print("🧩 CommunityService: Error loading posts: \(error.localizedDescription)")
            self.error = error.localizedDescription
            // Fall back to sample data
            posts = createSamplePosts()
        }
        isLoading = false
    }
    
    func createPost(content: String, imageURLs: [String] = [], location: PostLocation? = nil, groupId: String? = nil) async {
        guard let user = Auth.auth().currentUser else { return }
        
        let post = CommunityPost(
            userId: user.uid,
            author: user.displayName ?? "Anonymous",
            authorAvatar: user.photoURL?.absoluteString,
            content: content,
            originalLanguage: "en", // TODO: Detect language
            timestamp: Date(),
            likes: 0,
            comments: 0,
            imageURLs: imageURLs,
            location: location,
            groupId: groupId,
            likedBy: []
        )
        
        do {
            try db.collection("community_posts").addDocument(from: post)
            await loadPosts()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func likePost(_ postId: String) async {
        // Get the current user, or use "currentUser" for testing when not signed in
        let userId = Auth.auth().currentUser?.uid ?? "currentUser"
        
        let postRef = db.collection("community_posts").document(postId)
        
        do {
            try await db.runTransaction { transaction, errorPointer in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(postRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                guard var post = try? document.data(as: CommunityPost.self) else {
                    let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve post"])
                    errorPointer?.pointee = error
                    return nil
                }
                
                if post.likedBy.contains(userId) {
                    post.likedBy.removeAll { $0 == userId }
                    post.likes = max(0, post.likes - 1)
                } else {
                    post.likedBy.append(userId)
                    post.likes += 1
                }
                
                do {
                    try transaction.setData(from: post, forDocument: postRef)
                } catch let setError as NSError {
                    errorPointer?.pointee = setError
                    return nil
                }
                return nil
            }
            
            await loadPosts()
            
            // Post a notification to refresh all instances of the feed
            NotificationCenter.default.post(name: NSNotification.Name("RefreshCommunityFeed"), object: nil)
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Comments
    func addComment(to postId: String, content: String) async {
        guard let user = Auth.auth().currentUser else { return }
        
        do {
            // Create the comment
            let comment = PostComment(
                id: nil,
                postId: postId,
                userId: user.uid,
                author: user.displayName ?? "Anonymous",
                authorAvatar: user.photoURL?.absoluteString,
                content: content,
                originalLanguage: Locale.current.languageCode ?? "en",
                timestamp: Date(),
                likes: 0,
                likedBy: []
            )
            
            // Add the comment to Firestore
            let _ = try await db.collection("post_comments").addDocument(from: comment)
            
            // Update the post's comment count
            let postRef = db.collection("community_posts").document(postId)
            try await db.runTransaction { transaction, errorPointer in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(postRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                guard var post = try? document.data(as: CommunityPost.self) else {
                    let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve post"])
                    errorPointer?.pointee = error
                    return nil
                }
                
                post.comments += 1
                
                do {
                    try transaction.setData(from: post, forDocument: postRef)
                } catch let setError as NSError {
                    errorPointer?.pointee = setError
                    return nil
                }
                return nil
            }
            
            // Reload posts to update UI
            await loadPosts()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // Get comments for a post
    func getComments(for postId: String) async -> [PostComment] {
        do {
            let snapshot = try await db.collection("post_comments")
                .whereField("postId", isEqualTo: postId)
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            var comments: [PostComment] = []
            for document in snapshot.documents {
                if let comment = try? document.data(as: PostComment.self) {
                    comments.append(comment)
                }
            }
            return comments
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }
    
    func translatePost(_ post: CommunityPost, to language: String) async -> CommunityPost {
        var updatedPost = post
        
        // Skip translation if target language is the same as original
        if post.originalLanguage == language {
            updatedPost.translatedContent = nil
            updatedPost.isTranslated = false
            return updatedPost
        }
        
        do {
            print("🌐 CommunityService: Translating post from \(post.originalLanguage) to \(language)")
            let translatedContent = try await translationService.translateText(post.content, to: language)
            updatedPost.translatedContent = translatedContent
            updatedPost.isTranslated = true
            updatedPost.translatedLanguage = language
            print("🌐 CommunityService: Translation successful")
        } catch {
            print("🌐 CommunityService: Translation error: \(error.localizedDescription)")
            // On error, clear any existing translation and show original
            updatedPost.translatedContent = nil
            updatedPost.isTranslated = false
            updatedPost.translatedLanguage = nil
            self.error = "Translation failed: \(error.localizedDescription)"
        }
        
        return updatedPost
    }
    
    // MARK: - Events
    func loadEvents() async {
        isLoading = true
        do {
            print("🧩 CommunityService: Starting to load events from Firestore")
            let snapshot = try await db.collection("community_events")
                .order(by: "date", descending: false)
                .getDocuments()
            
            print("🧩 CommunityService: Received \(snapshot.documents.count) events from Firestore")
            
            var fetchedEvents: [CommunityEvent] = []
            
            for document in snapshot.documents {
                do {
                    if let event = try? document.data(as: CommunityEvent.self) {
                        fetchedEvents.append(event)
                        print("🧩 CommunityService: Successfully decoded event: \(event.title)")
                    } else {
                        print("🧩 CommunityService: Failed to decode event document: \(document.documentID)")
                    }
                } catch {
                    print("🧩 CommunityService: Error decoding event: \(error.localizedDescription)")
                }
            }
            
            if fetchedEvents.isEmpty {
                print("🧩 CommunityService: No events fetched from Firestore, using sample data")
                // Keep using sample events that were loaded in init()
            } else {
                events = fetchedEvents
                print("🧩 CommunityService: Successfully loaded \(events.count) events")
            }
        } catch {
            print("🧩 CommunityService: Error loading events: \(error.localizedDescription)")
            self.error = error.localizedDescription
            // Keep using sample events that were loaded in init()
        }
        isLoading = false
    }
    
    func createEvent(title: String, description: String, date: Date, location: EventLocation, category: EventCategory, maxAttendees: Int, imageURLs: [String] = [], groupId: String? = nil) async {
        guard let user = Auth.auth().currentUser else { return }
        
        let event = CommunityEvent(
            userId: user.uid,
            title: title,
            description: description,
            originalLanguage: "en",
            date: date,
            location: location,
            attendees: [user.uid],
            maxAttendees: maxAttendees,
            imageURLs: imageURLs,
            groupId: groupId,
            category: category
        )
        
        do {
            try db.collection("community_events").addDocument(from: event)
            await loadEvents()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func joinEvent(_ eventId: String) async {
        guard let user = Auth.auth().currentUser else { return }
        
        let eventRef = db.collection("community_events").document(eventId)
        
        do {
            try await db.runTransaction { transaction, errorPointer in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(eventRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                guard var event = try? document.data(as: CommunityEvent.self) else {
                    let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve event"])
                    errorPointer?.pointee = error
                    return nil
                }
                
                if event.attendees.contains(user.uid) {
                    event.attendees.removeAll { $0 == user.uid }
                } else if event.attendees.count < event.maxAttendees {
                    event.attendees.append(user.uid)
                }
                
                do {
                    try transaction.setData(from: event, forDocument: eventRef)
                } catch let setError as NSError {
                    errorPointer?.pointee = setError
                    return nil
                }
                return nil
            }
            
            await loadEvents()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func leaveEvent(eventId: String) async {
        guard let user = Auth.auth().currentUser else { return }
        
        let eventRef = db.collection("community_events").document(eventId)
        
        do {
            try await db.runTransaction { transaction, errorPointer in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(eventRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                guard var event = try? document.data(as: CommunityEvent.self) else {
                    let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve event"])
                    errorPointer?.pointee = error
                    return nil
                }
                
                if event.attendees.contains(user.uid) {
                    event.attendees.removeAll { $0 == user.uid }
                }
                
                do {
                    try transaction.setData(from: event, forDocument: eventRef)
                } catch let setError as NSError {
                    errorPointer?.pointee = setError
                    return nil
                }
                return nil
            }
            
            await loadEvents()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Groups
    func loadGroups() async {
        isLoading = true
        do {
            print("🧩 CommunityService: Starting to load groups from Firestore")
            let snapshot = try await db.collection("community_groups")
                .getDocuments()
            
            print("🧩 CommunityService: Received \(snapshot.documents.count) groups from Firestore")
            
            var fetchedGroups: [CommunityGroup] = []
            
            for document in snapshot.documents {
                do {
                    if let group = try? document.data(as: CommunityGroup.self) {
                        fetchedGroups.append(group)
                        print("🧩 CommunityService: Successfully decoded group: \(group.name)")
                    } else {
                        print("🧩 CommunityService: Failed to decode group document: \(document.documentID)")
                    }
                } catch {
                    print("🧩 CommunityService: Error decoding group: \(error.localizedDescription)")
                }
            }
            
            if fetchedGroups.isEmpty {
                print("🧩 CommunityService: No groups fetched from Firestore, using sample data")
                // Keep using sample groups that were loaded in init()
            } else {
                groups = fetchedGroups
                print("🧩 CommunityService: Successfully loaded \(groups.count) groups")
            }
        } catch {
            print("🧩 CommunityService: Error loading groups: \(error.localizedDescription)")
            self.error = error.localizedDescription
            // Keep using sample groups that were loaded in init()
        }
        isLoading = false
    }
    
    func createGroup(name: String, description: String, category: GroupCategory, isPrivate: Bool = false, requiresApproval: Bool = false, imageURL: String? = nil) async {
        guard let user = Auth.auth().currentUser else { return }
        
        let group = CommunityGroup(
            name: name,
            description: description,
            originalLanguage: "en",
            createdBy: user.uid,
            createdAt: Date(),
            members: [user.uid],
            imageURL: imageURL,
            isPrivate: isPrivate,
            requiresApproval: requiresApproval,
            category: category
        )
        
        do {
            try db.collection("community_groups").addDocument(from: group)
            await loadGroups()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func joinGroup(_ groupId: String) async {
        guard let user = Auth.auth().currentUser else { return }
        
        let groupRef = db.collection("community_groups").document(groupId)
        
        do {
            try await groupRef.updateData([
                "members": FieldValue.arrayUnion([user.uid])
            ])
            await loadGroups()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func leaveGroup(groupId: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        let groupRef = db.collection("community_groups").document(groupId)
        
        do {
            try await groupRef.updateData([
                "members": FieldValue.arrayRemove([user.uid])
            ])
            await loadGroups()
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    func getPostsForGroup(groupId: String) async throws -> [CommunityPost] {
        do {
            let snapshot = try await db.collection("community_posts")
                .whereField("groupId", isEqualTo: groupId)
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                try? document.data(as: CommunityPost.self)
            }
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Chat
    func loadChatRooms() async {
        guard let user = Auth.auth().currentUser else { 
            print("🧩 CommunityService: No authenticated user, using sample chat rooms")
            return 
        }
        
        isLoading = true
        do {
            print("🧩 CommunityService: Starting to load chat rooms from Firestore")
            let snapshot = try await db.collection("chat_rooms")
                .whereField("participants", arrayContains: user.uid)
                .getDocuments()
            
            print("🧩 CommunityService: Received \(snapshot.documents.count) chat rooms from Firestore")
            
            var fetchedChatRooms: [ChatRoom] = []
            
            for document in snapshot.documents {
                do {
                    if let chatRoom = try? document.data(as: ChatRoom.self) {
                        fetchedChatRooms.append(chatRoom)
                        print("🧩 CommunityService: Successfully decoded chat room: \(chatRoom.name)")
                    } else {
                        print("🧩 CommunityService: Failed to decode chat room document: \(document.documentID)")
                    }
                } catch {
                    print("🧩 CommunityService: Error decoding chat room: \(error.localizedDescription)")
                }
            }
            
            if fetchedChatRooms.isEmpty {
                print("🧩 CommunityService: No chat rooms fetched from Firestore, using sample data")
                // Keep using sample chat rooms that were loaded in init()
            } else {
                chatRooms = fetchedChatRooms
                print("🧩 CommunityService: Successfully loaded \(chatRooms.count) chat rooms")
            }
        } catch {
            print("🧩 CommunityService: Error loading chat rooms: \(error.localizedDescription)")
            self.error = error.localizedDescription
            // Keep using sample chat rooms that were loaded in init()
        }
        isLoading = false
    }
    
    // MARK: - Messages
    func loadMessages(forChatId chatId: String) async -> [ChatMessage] {
        do {
            print("🧩 CommunityService: Loading messages for chat \(chatId)")
            let snapshot = try await db.collection("chat_messages")
                .whereField("chatId", isEqualTo: chatId)
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            print("🧩 CommunityService: Received \(snapshot.documents.count) messages")
            
            let messages = snapshot.documents.compactMap { document in
                try? document.data(as: ChatMessage.self)
            }
            
            if messages.isEmpty {
                print("🧩 CommunityService: No messages found, returning sample messages")
                return createSampleMessages(forChatId: chatId)
            }
            
            return messages
        } catch {
            print("🧩 CommunityService: Error loading messages: \(error.localizedDescription)")
            return createSampleMessages(forChatId: chatId)
        }
    }
    
    func translateMessage(message: ChatMessage, to language: String) async -> ChatMessage {
        var updatedMessage = message
        
        // Skip translation if target language is the same as original
        if message.originalLanguage == language {
            updatedMessage.translatedContent = nil
            return updatedMessage
        }
        
        do {
            print("🌐 CommunityService: Translating message from \(message.originalLanguage) to \(language)")
            let translatedContent = try await translationService.translateText(message.content, to: language)
            updatedMessage.translatedContent = translatedContent
            print("🌐 CommunityService: Translation successful")
        } catch {
            print("🌐 CommunityService: Translation error: \(error.localizedDescription)")
            // On error, clear any existing translation
            updatedMessage.translatedContent = nil
            self.error = "Translation failed: \(error.localizedDescription)"
        }
        
        return updatedMessage
    }
    
    func sendMessage(toChatId chatId: String, content: String, messageType: MessageType = .text, imageURLs: [String] = []) async {
        guard let user = Auth.auth().currentUser else { return }
        
        let message = ChatMessage(
            senderId: user.uid,
            senderName: user.displayName ?? "Anonymous",
            senderAvatar: user.photoURL?.absoluteString,
            content: content,
            originalLanguage: "en", // TODO: Detect language
            timestamp: Date(),
            chatId: chatId,
            messageType: messageType,
            imageURLs: imageURLs
        )
        
        do {
            try await db.collection("chat_messages").addDocument(from: message)
            
            // Update last message in chat room
            let chatRef = db.collection("chat_rooms").document(chatId)
            try await chatRef.updateData([
                "lastMessage": content,
                "lastMessageTime": Date()
            ])
            
            // Reload chat rooms to update UI
            await loadChatRooms()
        } catch {
            print("🧩 CommunityService: Error sending message: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }
    
    private func createSampleMessages(forChatId chatId: String) -> [ChatMessage] {
        print("🧩 CommunityService: Creating sample messages for chat \(chatId)")
        return [
            ChatMessage(
                id: "1",
                senderId: "user2",
                senderName: "Sarah Johnson",
                senderAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800",
                content: "Hey everyone! Has anyone been to the property viewing yesterday?",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-3600),
                chatId: chatId,
                messageType: .text,
                imageURLs: []
            ),
            ChatMessage(
                id: "2",
                senderId: "user3",
                senderName: "Mike Chen",
                senderAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
                content: "Yes! The downtown apartment was amazing. Definitely going to bid on it! 🏢",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-3000),
                chatId: chatId,
                messageType: .text,
                imageURLs: []
            ),
            ChatMessage(
                id: "3",
                senderId: "currentUser",
                senderName: "Me",
                senderAvatar: nil,
                content: "That's great! What's your strategy for the auction?",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-2400),
                chatId: chatId,
                messageType: .text,
                imageURLs: []
            ),
            ChatMessage(
                id: "4",
                senderId: "user2",
                senderName: "Sarah Johnson",
                senderAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800",
                content: "I'm still researching the area. The market seems pretty competitive lately 📊",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-1800),
                chatId: chatId,
                messageType: .text,
                imageURLs: []
            ),
            ChatMessage(
                id: "5",
                senderId: "user4",
                senderName: "Alex Rodriguez",
                senderAvatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800",
                content: "¡Hola! ¿Alguien sabe sobre las propiedades en el área norte?",
                originalLanguage: "es",
                timestamp: Date().addingTimeInterval(-1200),
                chatId: chatId,
                messageType: .text,
                imageURLs: []
            ),
            ChatMessage(
                id: "6",
                senderId: "user3",
                senderName: "Mike Chen",
                senderAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
                content: "Welcome Alex! I can help with information about north area properties. There are some great opportunities there! 🎯",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-600),
                chatId: chatId,
                messageType: .text,
                imageURLs: []
            )
        ]
    }
    
    func createChatRoom(name: String, participants: [String], isGroup: Bool = true, groupId: String? = nil) async -> String? {
        guard let user = Auth.auth().currentUser else { return nil }
        
        let chatRoom = ChatRoom(
            name: name,
            description: nil,
            participants: participants + [user.uid],
            createdBy: user.uid,
            createdAt: Date(),
            lastMessage: nil,
            lastMessageTime: nil,
            isGroup: isGroup,
            imageURL: nil,
            groupId: groupId
        )
        
        do {
            let documentRef = try db.collection("chat_rooms").addDocument(from: chatRoom)
            await loadChatRooms()
            return documentRef.documentID
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Sample Data
    private func loadSampleData() {
        print("🧩 CommunityService: Loading sample data")
        // Sample Posts
        posts = createSamplePosts()
        
        // Sample Events
        events = [
            CommunityEvent(
                id: "1",
                userId: "user1",
                title: "Real Estate Investment Workshop",
                description: "Learn the basics of real estate investment and bidding strategies in Sri Lanka. Topics include market analysis, financial planning, and bidding tactics.",
                originalLanguage: "en",
                date: Date().addingTimeInterval(86400 * 3),
                location: EventLocation(name: "Colombo Business Center", address: "42 Galle Road, Colombo 03", latitude: 6.9271, longitude: 79.8612),
                attendees: ["user1", "user2", "user3", "user4"],
                maxAttendees: 100,
                imageURLs: ["https://images.unsplash.com/photo-1431540015161-0bf868a2d407?w=800"],
                groupId: "3", // Colombo Property Investors
                category: .workshop
            ),
            CommunityEvent(
                id: "2",
                userId: "user2",
                title: "Property Viewing Day - Luxury Apartments",
                description: "Open house for upcoming auction properties in Colombo's most prestigious neighborhoods. View multiple properties in one day with our guided tour.",
                originalLanguage: "en",
                date: Date().addingTimeInterval(86400 * 7),
                location: EventLocation(name: "Multiple Locations", address: "Starting at One Galle Face, Colombo", latitude: 6.9271, longitude: 79.8612),
                attendees: ["user1", "user2", "user3"],
                maxAttendees: 25,
                imageURLs: ["https://images.unsplash.com/photo-1515263487990-61b07816b324?w=800"],
                groupId: "2", // Luxury Properties
                category: .viewing
            ),
            CommunityEvent(
                id: "3",
                userId: "user3",
                title: "First-Time Homebuyers Seminar",
                description: "Everything you need to know about buying your first property in Sri Lanka. Experts will cover loans, legal requirements, and how to find the right property.",
                originalLanguage: "en",
                date: Date().addingTimeInterval(86400 * 14),
                location: EventLocation(name: "Kingsbury Hotel", address: "48 Janadhipathi Mawatha, Colombo", latitude: 6.9344, longitude: 79.8428),
                attendees: ["user2", "user5"],
                maxAttendees: 75,
                imageURLs: ["https://images.unsplash.com/photo-1556155092-490a1ba16284?w=800"],
                groupId: "1", // First Time Buyers
                category: .seminar
            ),
            CommunityEvent(
                id: "4",
                userId: "user4",
                title: "Property Tax and Legal Updates 2025",
                description: "Stay updated on the latest property laws, tax implications, and regulatory changes affecting the Sri Lankan real estate market.",
                originalLanguage: "en",
                date: Date().addingTimeInterval(86400 * 5),
                location: EventLocation(name: "Hilton Colombo", address: "2 Sir Chittampalam A Gardiner Mawatha, Colombo", latitude: 6.9344, longitude: 79.8428),
                attendees: ["user3", "user4", "user5"],
                maxAttendees: 50,
                imageURLs: ["https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=800"],
                groupId: "4", // Property Law Updates
                category: .seminar
            ),
            CommunityEvent(
                id: "5",
                userId: "user5",
                title: "Networking Mixer - Kandy Property Professionals",
                description: "Connect with fellow real estate professionals in Kandy. Share insights, build partnerships, and discover new opportunities in the Central Province market.",
                originalLanguage: "en",
                date: Date().addingTimeInterval(86400 * 10),
                location: EventLocation(name: "Earl's Regency Hotel", address: "Tennekumbura, Kandy", latitude: 7.2906, longitude: 80.6337),
                attendees: ["user3", "user5"],
                maxAttendees: 40,
                imageURLs: ["https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800"],
                groupId: "5", // Kandy Realtors Network
                category: .networking
            )
        ]
        
        // Sample Groups
        groups = [
            CommunityGroup(
                id: "1",
                name: "First Time Buyers",
                description: "Support group for people buying their first property in Sri Lanka",
                originalLanguage: "en",
                createdBy: "user1",
                createdAt: Date().addingTimeInterval(-86400 * 30),
                members: ["user1", "user2", "user3"],
                imageURL: "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800",
                isPrivate: false,
                requiresApproval: false,
                category: .firstTimeBuyers
            ),
            CommunityGroup(
                id: "2",
                name: "Luxury Properties",
                description: "Discuss high-end property investments and auctions in Sri Lanka's prime locations",
                originalLanguage: "en",
                createdBy: "user2",
                createdAt: Date().addingTimeInterval(-86400 * 15),
                members: ["user2", "user3"],
                imageURL: "https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=800",
                isPrivate: true,
                requiresApproval: true,
                category: .luxury
            ),
            CommunityGroup(
                id: "3",
                name: "Colombo Property Investors",
                description: "A group for property investors in Colombo to share tips, opportunities, and market insights",
                originalLanguage: "en",
                createdBy: "user3",
                createdAt: Date().addingTimeInterval(-86400 * 45),
                members: ["user1", "user3", "user4", "user5"],
                imageURL: "https://images.unsplash.com/photo-1542856204-00101eb6def4?w=800",
                isPrivate: false,
                requiresApproval: false,
                category: .investors
            ),
            CommunityGroup(
                id: "4",
                name: "Property Law Updates",
                description: "Stay informed about the latest changes in Sri Lankan property laws, regulations, and tax implications",
                originalLanguage: "en",
                createdBy: "user4",
                createdAt: Date().addingTimeInterval(-86400 * 60),
                members: ["user2", "user4", "user5"],
                imageURL: "https://images.unsplash.com/photo-1571624436279-b272aff752b5?w=800",
                isPrivate: false,
                requiresApproval: true,
                category: .legal
            ),
            CommunityGroup(
                id: "5",
                name: "Kandy Realtors Network",
                description: "Connecting real estate professionals in the Kandy region for collaboration and business growth",
                originalLanguage: "en",
                createdBy: "user5",
                createdAt: Date().addingTimeInterval(-86400 * 20),
                members: ["user3", "user5"],
                imageURL: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800",
                isPrivate: true,
                requiresApproval: true,
                category: .local
            )
        ]
        
        // Sample Chat Rooms
        chatRooms = [
            ChatRoom(
                id: "1",
                name: "General Property Discussion",
                description: "Main community chat for all VistaBids users to discuss property market trends",
                participants: ["user1", "user2", "user3", "user4", "user5"],
                createdBy: "user1",
                createdAt: Date().addingTimeInterval(-86400 * 7),
                lastMessage: "Has anyone noticed the rising prices in the Colombo 7 area lately?",
                lastMessageTime: Date().addingTimeInterval(-1800),
                isGroup: true,
                imageURL: "https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=800",
                groupId: nil
            ),
            ChatRoom(
                id: "2",
                name: "Sarah Johnson",
                description: nil,
                participants: ["user1", "user2"],
                createdBy: "user1",
                createdAt: Date().addingTimeInterval(-86400 * 3),
                lastMessage: "Thanks for the property tip! I'll check out that area this weekend.",
                lastMessageTime: Date().addingTimeInterval(-3600),
                isGroup: false,
                imageURL: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800",
                groupId: nil
            ),
            ChatRoom(
                id: "3",
                name: "First Time Buyers Chat",
                description: "Private chat for members of the First Time Buyers group",
                participants: ["user1", "user2", "user3"],
                createdBy: "user1",
                createdAt: Date().addingTimeInterval(-86400 * 14),
                lastMessage: "Has anyone used the government's new first-time buyer subsidy program?",
                lastMessageTime: Date().addingTimeInterval(-12600),
                isGroup: true,
                imageURL: "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800",
                groupId: "1" // First Time Buyers group
            ),
            ChatRoom(
                id: "4",
                name: "Mike Chen",
                description: nil,
                participants: ["user1", "user3"],
                createdBy: "user3",
                createdAt: Date().addingTimeInterval(-86400 * 5),
                lastMessage: "I'm interested in that beachfront property you mentioned. Is it still on the market?",
                lastMessageTime: Date().addingTimeInterval(-7200),
                isGroup: false,
                imageURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
                groupId: nil
            ),
            ChatRoom(
                id: "5",
                name: "Luxury Property Investments",
                description: "Exclusive chat for high-end property investors",
                participants: ["user2", "user3", "user5"],
                createdBy: "user2",
                createdAt: Date().addingTimeInterval(-86400 * 10),
                lastMessage: "The new development in Colombo 7 is opening for pre-auction bids next week.",
                lastMessageTime: Date().addingTimeInterval(-5400),
                isGroup: true,
                imageURL: "https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=800",
                groupId: "2" // Luxury Properties group
            )
        ]
    }
    
    // Helper method to create sample posts
    func createSamplePosts() -> [CommunityPost] {
        print("🧩 CommunityService: Creating sample posts")
        
        // Get current user ID for like status
        let currentUserId = Auth.auth().currentUser?.uid ?? "currentUser"
        
        return [
            CommunityPost(
                id: "1",
                userId: "user1",
                author: "John Smith",
                authorAvatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800",
                content: "Just sold my first property through VistaBids! The auction process was seamless and I got a great price. Highly recommend! 🏡✨",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-3600),
                likes: 24,
                comments: 8,
                imageURLs: ["https://images.unsplash.com/photo-1513584684374-8bab748fbf90?w=800"],
                location: nil,
                groupId: nil,
                likedBy: ["user3", "user5"]
            ),
            CommunityPost(
                id: "2",
                userId: "user2",
                author: "Sarah Johnson",
                authorAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800",
                content: "Looking for advice on property staging for auctions. What are the key things that attract bidders?",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-7200),
                likes: 15,
                comments: 12,
                imageURLs: [],
                location: nil,
                groupId: nil,
                likedBy: [currentUserId, "user4"]
            ),
            CommunityPost(
                id: "3",
                userId: "user3",
                author: "Mike Chen",
                authorAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800",
                content: "Market update: Properties in downtown area are seeing 20% higher bidding activity this month! 📈",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-14400),
                likes: 31,
                comments: 6,
                imageURLs: ["https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800"],
                location: nil,
                groupId: nil,
                likedBy: ["user2", "user5", currentUserId]
            ),
            CommunityPost(
                id: "4",
                userId: "user4",
                author: "Emily Davis",
                authorAvatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800",
                content: "Just finished renovating my investment property! Before and after photos attached. What do you think? #HomeRenovation",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-86400),
                likes: 47,
                comments: 23,
                imageURLs: [
                    "https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800",
                    "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800"
                ],
                location: PostLocation(
                    name: "Colombo, Sri Lanka",
                    latitude: 6.9271,
                    longitude: 79.8612,
                    address: "Colombo, Western Province"
                ),
                groupId: nil,
                likedBy: ["user1", "user2", "user5", "currentUser"]
            ),
            CommunityPost(
                id: "5",
                userId: "user5",
                author: "David Wilson",
                authorAvatar: "https://images.unsplash.com/photo-1568602471122-7832951cc4c5?w=800",
                content: "Any recommendations for property lawyers in the Kandy area? Need help with some paperwork for my upcoming auction.",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-172800),
                likes: 8,
                comments: 15,
                imageURLs: [],
                location: PostLocation(
                    name: "Kandy, Sri Lanka",
                    latitude: 7.2906,
                    longitude: 80.6337,
                    address: "Kandy, Central Province"
                ),
                groupId: nil,
                likedBy: [currentUserId, "user3"]
            ),
            // Multi-language sample posts for testing translation
            CommunityPost(
                id: "6",
                userId: "user6",
                author: "María García",
                authorAvatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800",
                content: "¡Hola a todos! Estoy buscando propiedades de inversión en Colombo. ¿Alguien tiene experiencia en el mercado inmobiliario de Sri Lanka?",
                originalLanguage: "es",
                timestamp: Date().addingTimeInterval(-25200),
                likes: 12,
                comments: 5,
                imageURLs: [],
                location: nil,
                groupId: nil,
                likedBy: []
            ),
            CommunityPost(
                id: "7",
                userId: "user7",
                author: "Pierre Dubois",
                authorAvatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800",
                content: "Bonjour! Je cherche à acheter une propriété au bord de mer. Quelqu'un peut-il me donner des conseils sur les enchères immobilières?",
                originalLanguage: "fr",
                timestamp: Date().addingTimeInterval(-43200),
                likes: 18,
                comments: 9,
                imageURLs: ["https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800"],
                location: nil,
                groupId: nil,
                likedBy: []
            ),
            CommunityPost(
                id: "8",
                userId: "user8",
                author: "田中太郎",
                authorAvatar: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800",
                content: "スリランカの不動産市場について興味があります。オークションでの物件購入について教えてください。",
                originalLanguage: "ja",
                timestamp: Date().addingTimeInterval(-61200),
                likes: 9,
                comments: 3,
                imageURLs: [],
                location: nil,
                groupId: nil,
                likedBy: []
            ),
            CommunityPost(
                id: "9",
                userId: "user9",
                author: "王小明",
                authorAvatar: "https://images.unsplash.com/photo-1519345182560-3f2917c472ef?w=800",
                content: "大家好！我在寻找科伦坡的投资房产。有人可以分享一下拍卖经验吗？",
                originalLanguage: "zh",
                timestamp: Date().addingTimeInterval(-79200),
                likes: 14,
                comments: 7,
                imageURLs: ["https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800"],
                location: nil,
                groupId: nil,
                likedBy: []
            )
        ]
    }
}
