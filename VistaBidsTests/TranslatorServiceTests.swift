//
//  TranslatorServiceTests.swift
//  VistaBidsTests
//
//  Created by Ruvindu Dulaksha on 2025-09-19.
//

import Testing
import Foundation
@testable import VistaBids

struct TranslatorServiceTests {

    @Test func testTranslateEnglishToSinhala() async throws {
        // Given
        let translator = await TranslatorService.shared
        let text = "Hello world"

        // When
        let translated = try await translator.translate(text: text, from: .english, to: .sinhala)

        // Then
        #expect(translated == "ආයුබෝවන් world")
    }

    @Test func testTranslateEnglishToTamil() async throws {
        // Given
        let translator = await TranslatorService.shared
        let text = "Good morning"

        // When
        let translated = try await translator.translate(text: text, from: .english, to: .tamil)

        // Then
        #expect(translated == "காலை வணக்கம்")
    }

    @Test func testTranslateWordByWord() async throws {
        // Given
        let translator = await TranslatorService.shared
        let text = "My land flowers"

        // When
        let translated = try await translator.translate(text: text, from: .english, to: .sinhala)

        // Then
        #expect(translated == "මගේ භූමිය මල්")
    }

    @Test func testTranslateUnknownWord() async throws {
        // Given
        let translator = await TranslatorService.shared
        let text = "UnknownWord test"

        // When
        let translated = try await translator.translate(text: text, from: .english, to: .sinhala)

        // Then
        #expect(translated == "[සිංහල] UnknownWord test")
    }

        @Test func testDetectLanguageEnglish() async throws {
        // Given
        let translator = await TranslatorService.shared
        let text = "Hello world"

        // When
        let detected = try await translator.detectLanguageEnum(text: text)

        // Then
        #expect(detected == .english)
    }

    @Test func testDetectLanguageSinhala() async throws {
        // Given
        let translator = await TranslatorService.shared
        let text = "ආයුබෝවන් සිංහලෙන්"

        // When
        let detected = try await translator.detectLanguageEnum(text: text)

        // Then
        #expect(detected == .sinhala)
    }

    @Test func testDetectLanguageTamil() async throws {
        // Given
        let translator = await TranslatorService.shared
        let text = "வணக்கம் தமிழில்"

        // When
        let detected = try await translator.detectLanguageEnum(text: text)

        // Then
        #expect(detected == .tamil)
    }

    @Test func testTranslateTextProtocol() async throws {
        // Given
        let translator = await TranslatorService.shared
        let text = "Thank you"

        // When
        let translated = try await translator.translateText(text, to: "si")

        // Then
        #expect(translated == "ස්තුතියි")
    }

}