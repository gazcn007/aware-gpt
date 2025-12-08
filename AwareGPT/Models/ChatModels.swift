//
//  ChatModels.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var messages: [Message] = []
    
    init(title: String = "New Chat") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
    }
}

@Model
final class Message {
    var id: UUID
    var roleRawValue: String
    var content: String
    var createdAt: Date
    var conversation: Conversation?
    var hallucinationScore: Double? // 0.0 to 1.0, where higher = more likely to be hallucination
    
    var role: MessageRole {
        get { MessageRole(rawValue: roleRawValue) ?? .user }
        set { roleRawValue = newValue.rawValue }
    }
    
    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.roleRawValue = role.rawValue
        self.content = content
        self.createdAt = Date()
        self.hallucinationScore = nil
    }
}

