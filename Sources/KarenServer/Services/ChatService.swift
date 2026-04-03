//
//  ChatService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/23/26.
//
import Foundation
import Fluent

struct ChatService {
    let llmService = LLMService()
    
    func send(conversationID: UUID, content: String, on db: any Database) async throws -> Message {
        
        let message = Message(
            id: UUID(),
            conversationID: conversationID,
            content: content,
            role: "user",
            timestamp: Date.now
        )
        
        try await message.save(on: db)
        
        //TODO: Doublecheck after LLM Completion for validity
        let response = try await llmService.generateResponse(message)
        
        return response;
    }
    
    func getMessages(conversationID: UUID, on db: any Database) async throws -> [Message] {
        return try await Message.query(on: db)
            .filter(\.$conversationID == conversationID)
            .sort(\.$timestamp, .ascending)
            .all()
    }
}
