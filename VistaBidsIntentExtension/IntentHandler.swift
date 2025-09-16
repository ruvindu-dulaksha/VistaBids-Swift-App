//
//  IntentHandler.swift
//  VistaBidsIntentExtension
//
//  Created by Assistant on 2025-09-15.
//

import Intents

@available(iOS 13.0, *)
class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        print("🎤 SiriKit: Handling intent: \(type(of: intent))")
        
        if intent is PlaceBidIntent {
            return PlaceBidIntentHandler()
        }
        
        // Handle other intents here if needed
        fatalError("Unhandled intent type: \(intent)")
    }
}
