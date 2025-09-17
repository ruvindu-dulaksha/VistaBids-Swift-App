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

// Community Service
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
        print("🧩 CommunityService: Initializing...")
        // Load sample data first, then try to load from Firebase
        loadSampleData()
        print("🧩 CommunityService: Sample data loaded, posts count: \(posts.count)")
        Task {
            print("🧩 CommunityService: Starting async loadPosts task...")
            await loadPosts()
        }
    }
    
    // Posts
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
            
            if fetchedPosts.isEmpty && posts.isEmpty {
                print("🧩 CommunityService: No posts in Firestore and no existing posts, uploading sample data")
                await uploadSamplePostsToFirebase()
                return // uploadSamplePostsToFirebase will call loadPosts again
            } else if fetchedPosts.isEmpty && !posts.isEmpty {
                print("🧩 CommunityService: No posts in Firestore but we have \(posts.count) existing posts, keeping them")
                // Keep existing sample posts
            } else if !fetchedPosts.isEmpty {
                print("🧩 CommunityService: Successfully loaded \(fetchedPosts.count) posts from Firestore, replacing local posts")
                DispatchQueue.main.async {
                    self.posts = fetchedPosts
                }
                print("🧩 CommunityService: Posts updated on main thread, new count: \(posts.count)")
            } else {
                print("🧩 CommunityService: No new posts from Firestore, keeping existing \(posts.count) posts")
                // Keep existing posts if Firestore query returns empty but we have existing posts
            }
        } catch {
            print("🧩 CommunityService: Error loading posts: \(error.localizedDescription)")
            self.error = error.localizedDescription
            // If no existing posts and there's an error, try to upload sample data
            if posts.isEmpty {
                print("🧩 CommunityService: No existing posts, trying to upload sample data due to error")
                await uploadSamplePostsToFirebase()
                return // uploadSamplePostsToFirebase will call loadPosts again
            } else {
                print("🧩 CommunityService: Preserving existing \(posts.count) posts due to Firestore error")
            }
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
            originalLanguage: "en", 
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
    
    //  Comments
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
    
    // Events
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
    
    //Groups
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
    
    // Chat
    func loadChatRooms() async {
        // If no authenticated user, just use the sample data that was loaded in init()
        guard let user = Auth.auth().currentUser else { 
            print("🧩 CommunityService: No authenticated user, using sample chat rooms")
            isLoading = false
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
                print("🧩 CommunityService: No chat rooms fetched from Firestore, keeping sample data")
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
    
    // Messages
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
                authorAvatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face",
                content: "Just sold my first property through VistaBids! The auction process was seamless and I got a great price. Highly recommend! 🏡✨",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-3600),
                likes: 24,
                comments: 8,
                imageURLs: ["https://images.unsplash.com/photo-1513584684374-8bab748fbf90?w=800&h=600&fit=crop"],
                location: nil,
                groupId: nil,
                likedBy: ["user3", "user5"]
            ),
            CommunityPost(
                id: "2",
                userId: "user2",
                author: "Sarah Johnson",
                authorAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop&crop=face",
                content: "Beautiful modern apartment just listed for auction! Located in the heart of the city with amazing skyline views. Perfect for young professionals. What do you think? 🏙️",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-7200),
                likes: 15,
                comments: 12,
                imageURLs: [
                    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&h=600&fit=crop",
                    "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&h=600&fit=crop",
                    "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&h=600&fit=crop"
                ],
                location: nil,
                groupId: nil,
                likedBy: [currentUserId, "user4"]
            ),
            CommunityPost(
                id: "3",
                userId: "user3",
                author: "Mike Chen",
                authorAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
                content: "Market update: Properties in downtown area are seeing 20% higher bidding activity this month! Great time to sell. 📈",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-14400),
                likes: 31,
                comments: 6,
                imageURLs: ["https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&h=600&fit=crop"],
                location: nil,
                groupId: nil,
                likedBy: ["user1", "user4", "user7"]
            ),
            CommunityPost(
                id: "4",
                userId: "user4",
                author: "Lisa Wong",
                authorAvatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
                content: "Amazing luxury villa with pool and garden! Check out these stunning photos from today's viewing. The auction starts tomorrow! 🏊‍♂️🌺",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-21600),
                likes: 45,
                comments: 18,
                imageURLs: [
                    "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&h=600&fit=crop",
                    "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&h=600&fit=crop",
                    "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&h=600&fit=crop",
                    "https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=800&h=600&fit=crop"
                ],
                location: PostLocation(name: "Beverly Hills", latitude: 34.0736, longitude: -118.4004, address: "Beverly Hills, CA"),
                groupId: nil,
                likedBy: ["user1", "user2", "user5", "user6"]
            ),
            CommunityPost(
                id: "5",
                userId: "user5",
                author: "David Kim",
                authorAvatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
                content: "Tips for first-time property auction bidders: Set your budget and stick to it! Don't get caught up in the excitement. Research is key! 💡",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-28800),
                likes: 67,
                comments: 23,
                imageURLs: [],
                location: nil,
                groupId: "2", // First Time Buyers
                likedBy: ["user1", "user2", "user3", currentUserId, "user6", "user7"]
            ),
            CommunityPost(
                id: "6",
                userId: "user6",
                author: "Emma Rodriguez",
                authorAvatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face",
                content: "Coastal property with breathtaking ocean views! Perfect for vacation rental investment. The sound of waves every morning... 🌊🏖️",
                originalLanguage: "en",
                timestamp: Date().addingTimeInterval(-36000),
                likes: 52,
                comments: 14,
                imageURLs: [
                    "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800&h=600&fit=crop",
                    "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=800&h=600&fit=crop"
                ],
                location: PostLocation(name: "Malibu Beach", latitude: 34.0259, longitude: -118.7798, address: "Malibu, CA"),
                groupId: nil,
                likedBy: ["user2", "user3", "user4", "user7"]
            )
        ]
    }
    
    // Upload Sample Data to Firebase
    func uploadSamplePostsToFirebase() async {
        print("🔥 CommunityService: Starting to upload sample posts to Firebase")
        let samplePosts = createSamplePosts()
        
        var uploadedCount = 0
        for post in samplePosts {
            do {
                let _ = try await db.collection("community_posts").addDocument(from: post)
                uploadedCount += 1
                print("🔥 CommunityService: Successfully uploaded post \(uploadedCount): \(post.content.prefix(50))...")
            } catch {
                print("🔥 CommunityService: Error uploading post: \(error.localizedDescription)")
            }
        }
        
        print("🔥 CommunityService: Upload complete. \(uploadedCount)/\(samplePosts.count) posts uploaded")
        
        // Wait a moment for Firestore to process, then reload
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Force reload from Firestore after upload
        print("🔥 CommunityService: Force reloading posts after upload...")
        isLoading = true
        do {
            let snapshot = try await db.collection("community_posts")
                .order(by: "timestamp", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            print("🔥 CommunityService: Found \(snapshot.documents.count) posts after upload")
            
            var fetchedPosts: [CommunityPost] = []
            for document in snapshot.documents {
                if let post = try? document.data(as: CommunityPost.self) {
                    fetchedPosts.append(post)
                }
            }
            
            DispatchQueue.main.async {
                self.posts = fetchedPosts
                print("🔥 CommunityService: Updated posts on main thread, new count: \(self.posts.count)")
            }
        } catch {
            print("🔥 CommunityService: Error reloading after upload: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    // Clear and Refresh Firebase Data
    func clearAndUploadFreshData() async {
        print("🧹 CommunityService: Clearing existing posts and uploading fresh data")
        
        // First clear existing posts
        do {
            let snapshot = try await db.collection("community_posts").getDocuments()
            print("🧹 CommunityService: Found \(snapshot.documents.count) existing posts to delete")
            
            for document in snapshot.documents {
                try await document.reference.delete()
            }
            print("🧹 CommunityService: Cleared all existing posts")
        } catch {
            print("🧹 CommunityService: Error clearing posts: \(error.localizedDescription)")
        }
        
        // Now upload fresh sample data
        await uploadSamplePostsToFirebase()
    }
}
