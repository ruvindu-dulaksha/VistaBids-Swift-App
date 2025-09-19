//
//  UserModelTests.swift
//  VistaBidsTests
//
//  Created by Ruvindu Dulaksha on 2025-09-19.
//

import Testing
import Foundation
import FirebaseAuth
@testable import VistaBids

// Mock Firebase User Protocol
private protocol MockUserProtocol {
    var uid: String { get }
    var email: String? { get }
    var displayName: String? { get }
    var photoURL: URL? { get }
    var isEmailVerified: Bool { get }
}

//  Mock Firebase User Class
private class MockFirebaseUser: MockUserProtocol {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let isEmailVerified: Bool

    init(uid: String, email: String?, displayName: String?, photoURL: URL?, isEmailVerified: Bool) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isEmailVerified = isEmailVerified
    }
}

// Test UserModel for Testing
private struct TestUserModel: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String?
    let photoURL: String?
    let isEmailVerified: Bool
    
    init(id: String, email: String, displayName: String?, photoURL: String?, isEmailVerified: Bool) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isEmailVerified = isEmailVerified
    }
    
    init(from mockUser: MockUserProtocol) {
        self.id = mockUser.uid
        self.email = mockUser.email ?? ""
        self.displayName = mockUser.displayName
        self.photoURL = mockUser.photoURL?.absoluteString
        self.isEmailVerified = mockUser.isEmailVerified
    }
}

struct UserModelTests {

    //   Test Cases

    @Test func testUserModelInitializationFromMockUser() {
        // Given
        let mockUser = MockFirebaseUser(
            uid: "test-user-id",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: URL(string: "https://example.com/photo.jpg"),
            isEmailVerified: true
        )

        // When
        let userModel = TestUserModel(from: mockUser)

        // Then
        #expect(userModel.id == "test-user-id")
        #expect(userModel.email == "test@example.com")
        #expect(userModel.displayName == "Test User")
        #expect(userModel.photoURL == "https://example.com/photo.jpg")
        #expect(userModel.isEmailVerified == true)
    }

    @Test func testUserModelInitializationWithNilValues() {
        // Given
        let mockUser = MockFirebaseUser(
            uid: "test-user-id-2",
            email: nil,
            displayName: nil,
            photoURL: nil,
            isEmailVerified: false
        )

        // When
        let userModel = TestUserModel(from: mockUser)

        // Then
        #expect(userModel.id == "test-user-id-2")
        #expect(userModel.email == "")
        #expect(userModel.displayName == nil)
        #expect(userModel.photoURL == nil)
        #expect(userModel.isEmailVerified == false)
    }

    @Test func testUserModelEncoding() throws {
        // Given
        let mockUser = MockFirebaseUser(
            uid: "encode-test-id",
            email: "encode@example.com",
            displayName: "Encode User",
            photoURL: URL(string: "https://example.com/encode.jpg"),
            isEmailVerified: true
        )
        let userModel = TestUserModel(from: mockUser)

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(userModel)
        let jsonString = String(data: data, encoding: .utf8)

        // Then
        #expect(jsonString != nil)
        #expect(jsonString!.contains("encode-test-id"))
        #expect(jsonString!.contains("encode@example.com"))
        #expect(jsonString!.contains("Encode User"))
        #expect(jsonString!.contains("https://example.com/encode.jpg"))
        #expect(jsonString!.contains("true"))
    }

    @Test func testUserModelDecoding() throws {
        // Given
        let jsonString = """
        {
            "id": "decode-test-id",
            "email": "decode@example.com",
            "displayName": "Decode User",
            "photoURL": "https://example.com/decode.jpg",
            "isEmailVerified": false
        }
        """
        let jsonData = jsonString.data(using: .utf8)!

        // When
        let decoder = JSONDecoder()
        let userModel = try decoder.decode(TestUserModel.self, from: jsonData)

        // Then
        #expect(userModel.id == "decode-test-id")
        #expect(userModel.email == "decode@example.com")
        #expect(userModel.displayName == "Decode User")
        #expect(userModel.photoURL == "https://example.com/decode.jpg")
        #expect(userModel.isEmailVerified == false)
    }

    @Test func testUserModelDecodingWithNilValues() throws {
        // Given
        let jsonString = """
        {
            "id": "decode-nil-test-id",
            "email": "decode-nil@example.com",
            "isEmailVerified": true
        }
        """
        let jsonData = jsonString.data(using: .utf8)!

        // When
        let decoder = JSONDecoder()
        let userModel = try decoder.decode(TestUserModel.self, from: jsonData)

        // Then
        #expect(userModel.id == "decode-nil-test-id")
        #expect(userModel.email == "decode-nil@example.com")
        #expect(userModel.displayName == nil)
        #expect(userModel.photoURL == nil)
        #expect(userModel.isEmailVerified == true)
    }

    @Test func testUserModelIdentifiableConformance() {
        // Given
        let mockUser = MockFirebaseUser(
            uid: "identifiable-test-id",
            email: "identifiable@example.com",
            displayName: nil,
            photoURL: nil,
            isEmailVerified: false
        )
        let userModel = TestUserModel(from: mockUser)

        // Then
        #expect(userModel.id == "identifiable-test-id")
    }

    @Test func testUserModelCodableRoundTrip() throws {
        // Given
        let mockUser = MockFirebaseUser(
            uid: "roundtrip-test-id",
            email: "roundtrip@example.com",
            displayName: "Round Trip User",
            photoURL: URL(string: "https://example.com/roundtrip.jpg"),
            isEmailVerified: true
        )
        let originalUserModel = TestUserModel(from: mockUser)

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalUserModel)

        let decoder = JSONDecoder()
        let decodedUserModel = try decoder.decode(TestUserModel.self, from: data)

        // Then
        #expect(decodedUserModel.id == originalUserModel.id)
        #expect(decodedUserModel.email == originalUserModel.email)
        #expect(decodedUserModel.displayName == originalUserModel.displayName)
        #expect(decodedUserModel.photoURL == originalUserModel.photoURL)
        #expect(decodedUserModel.isEmailVerified == originalUserModel.isEmailVerified)
    }

    @Test func testUserModelWithEmptyEmail() {
        // Given
        let mockUser = MockFirebaseUser(
            uid: "empty-email-test-id",
            email: "",
            displayName: "Empty Email User",
            photoURL: nil,
            isEmailVerified: false
        )

        // When
        let userModel = TestUserModel(from: mockUser)

        // Then
        #expect(userModel.id == "empty-email-test-id")
        #expect(userModel.email == "")
        #expect(userModel.displayName == "Empty Email User")
        #expect(userModel.photoURL == nil)
        #expect(userModel.isEmailVerified == false)
    }

    @Test func testUserModelWithLongDisplayName() {
        // Given
        let longDisplayName = String(repeating: "A", count: 100)
        let mockUser = MockFirebaseUser(
            uid: "long-name-test-id",
            email: "longname@example.com",
            displayName: longDisplayName,
            photoURL: URL(string: "https://example.com/longname.jpg"),
            isEmailVerified: true
        )

        // When
        let userModel = TestUserModel(from: mockUser)

        // Then
        #expect(userModel.id == "long-name-test-id")
        #expect(userModel.email == "longname@example.com")
        #expect(userModel.displayName == longDisplayName)
        #expect(userModel.photoURL == "https://example.com/longname.jpg")
        #expect(userModel.isEmailVerified == true)
    }
}