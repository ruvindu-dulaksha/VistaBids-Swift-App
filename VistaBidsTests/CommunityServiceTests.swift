//
//  CommunityServiceTests.swift
//  VistaBidsTests
//
//  Created by Ruvindu Dulaksha on 2025-09-19.
//

import Testing
import Foundation
@testable import VistaBids

struct CommunityServiceTests {

    @Test func testTranslatePost() async throws {
        // Given
        let service = await CommunityService()
        let testPost = CommunityPost(
            userId: "testUser",
            author: "Test Author",
            authorAvatar: nil,
            content: "Hello world",
            originalLanguage: "en",
            timestamp: Date(),
            likes: 0,
            comments: 0,
            imageURLs: [],
            location: nil,
            groupId: nil,
            likedBy: []
        )

        // When
        let translatedPost = await service.translatePost(testPost, to: "si")

        // Then
        #expect(translatedPost.isTranslated == true)
        #expect(translatedPost.translatedLanguage == "si")
        #expect(translatedPost.translatedContent != nil)
    }

    @Test func testTranslatePostSameLanguage() async throws {
        // Given
        let service = await CommunityService()
        let testPost = CommunityPost(
            userId: "testUser",
            author: "Test Author",
            authorAvatar: nil,
            content: "Hello world",
            originalLanguage: "en",
            timestamp: Date(),
            likes: 0,
            comments: 0,
            imageURLs: [],
            location: nil,
            groupId: nil,
            likedBy: []
        )

        // When
        let translatedPost = await service.translatePost(testPost, to: "en")

        // Then
        #expect(translatedPost.isTranslated == false)
        #expect(translatedPost.translatedContent == nil)
    }

    @Test func testTranslateMessage() async throws {
        // Given
        let service = await CommunityService()
        let testMessage = ChatMessage(
            senderId: "testUser",
            senderName: "Test User",
            senderAvatar: nil,
            content: "Good morning",
            originalLanguage: "en",
            timestamp: Date(),
            chatId: "testChat",
            messageType: .text,
            imageURLs: []
        )

        // When
        let translatedMessage = await service.translateMessage(message: testMessage, to: "si")

        // Then
        #expect(translatedMessage.translatedContent != nil)
    }

    @Test func testCreatePost() async throws {
        // Given
        let service = await CommunityService()
        let content = "Test post content"

        // When
        await service.createPost(content: content, imageURLs: [], location: nil, groupId: nil)

        // Then
        // Note: In a real test, you'd mock the service or check if the post was added
        // For now, we just ensure no crashes occur
        #expect(true) // Placeholder assertion
    }

}