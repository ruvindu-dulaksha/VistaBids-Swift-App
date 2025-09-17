//
//  TestImageStorageView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-24.
//

import SwiftUI
import UIKit

/// Test view to verify image storage and AR panorama functionality
struct TestImageStorageView: View {
    @State private var testResults: [String] = []
    @State private var isRunningTests = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Image Storage & AR Test")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                Button("Run Storage Tests") {
                    runTests()
                }
                .disabled(isRunningTests)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                if isRunningTests {
                    ProgressView("Running tests...")
                        .padding()
                }
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(testResults, id: \.self) { result in
                            HStack {
                                if result.hasPrefix("✅") {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else if result.hasPrefix("❌") {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                } else {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                }
                                
                                Text(result)
                                    .font(.caption)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Image Tests")
        }
    }
    
    private func runTests() {
        isRunningTests = true
        testResults.removeAll()
        
        Task {
            await performTests()
            await MainActor.run {
                isRunningTests = false
            }
        }
    }
    
    private func performTests() async {
        await addTestResult("🚀 Starting image storage tests...")
        
        // Test 1: Check Documents Directory
        await testDocumentsDirectory()
        
        // Test 2: Check Images Directory Creation
        await testImagesDirectoryCreation()
        
        // Test 3: Test Image Saving
        await testImageSaving()
        
        // Test 4: Test Image Loading
        await testImageLoading()
        
        // Test 5: Test Local URL Formats
        await testLocalURLFormats()
        
        await addTestResult("🎯 All tests completed!")
    }
    
    @MainActor
    private func addTestResult(_ result: String) async {
        testResults.append(result)
        print(result)
    }
    
    private func testDocumentsDirectory() async {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        await addTestResult("📁 Documents directory: \(documentsURL.path)")
        
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            await addTestResult("✅ Documents directory accessible")
        } else {
            await addTestResult("❌ Documents directory not accessible")
        }
    }
    
    private func testImagesDirectoryCreation() async {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesURL = documentsURL.appendingPathComponent("images")
        
        do {
            if !FileManager.default.fileExists(atPath: imagesURL.path) {
                try FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)
            }
            await addTestResult("✅ Images directory created/verified: \(imagesURL.path)")
        } catch {
            await addTestResult("❌ Failed to create images directory: \(error)")
        }
    }
    
    private func testImageSaving() async {
        // Create a test image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = testImage else {
            await addTestResult("❌ Failed to create test image")
            return
        }
        
        // Test saving to documents/images
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesURL = documentsURL.appendingPathComponent("images")
        let testFileName = "test_image_\(Int(Date().timeIntervalSince1970)).jpg"
        let testFileURL = imagesURL.appendingPathComponent(testFileName)
        
        do {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                try imageData.write(to: testFileURL)
                await addTestResult("✅ Test image saved: \(testFileName)")
                
                // Verify file exists
                if FileManager.default.fileExists(atPath: testFileURL.path) {
                    await addTestResult("✅ Test image file verified on disk")
                } else {
                    await addTestResult("❌ Test image file not found after saving")
                }
            } else {
                await addTestResult("❌ Failed to convert test image to JPEG data")
            }
        } catch {
            await addTestResult("❌ Failed to save test image: \(error)")
        }
    }
    
    private func testImageLoading() async {
        // Test loading the image we just saved
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesURL = documentsURL.appendingPathComponent("images")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: imagesURL, includingPropertiesForKeys: nil)
            let testFiles = files.filter { $0.lastPathComponent.hasPrefix("test_image_") }
            
            if let testFile = testFiles.first {
                if let loadedImage = UIImage(contentsOfFile: testFile.path) {
                    await addTestResult("✅ Successfully loaded test image: \(testFile.lastPathComponent)")
                    await addTestResult("📏 Loaded image size: \(loadedImage.size)")
                } else {
                    await addTestResult("❌ Failed to load test image from file")
                }
            } else {
                await addTestResult("❌ No test images found to load")
            }
        } catch {
            await addTestResult("❌ Error listing files in images directory: \(error)")
        }
    }
    
    private func testLocalURLFormats() async {
        await addTestResult("🔗 Testing local URL formats...")
        
        let testFormats = [
            "local://images/test.jpg",
            "local://test.jpg",
            "local:///Users/test/images/test.jpg"
        ]
        
        for format in testFormats {
            await addTestResult("🧪 Testing format: \(format)")
            
            // Test URL parsing
            if format.hasPrefix("local://") {
                let cleanPath = String(format.dropFirst(8))
                await addTestResult("   Clean path: \(cleanPath)")
                
                // Test different resolution strategies
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                
                var candidatePaths: [String] = []
                candidatePaths.append(documentsURL.appendingPathComponent(cleanPath).path)
                
                if !cleanPath.hasPrefix("images/") {
                    candidatePaths.append(documentsURL.appendingPathComponent("images").appendingPathComponent(cleanPath).path)
                }
                
                await addTestResult("   Candidate paths: \(candidatePaths.count)")
                for path in candidatePaths {
                    let exists = FileManager.default.fileExists(atPath: path)
                    await addTestResult("   \(exists ? "✅" : "❌") \(path)")
                }
            }
        }
    }
}

#Preview {
    TestImageStorageView()
}
