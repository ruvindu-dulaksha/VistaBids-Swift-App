//
//  UserModel.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-07-22.
//

import Foundation
import FirebaseAuth

struct UserModel: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String?
    let photoURL: String?
    let isEmailVerified: Bool
    
    init(from firebaseUser: User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL?.absoluteString
        self.isEmailVerified = firebaseUser.isEmailVerified
    }
}
