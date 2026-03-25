//
//  ChatService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/23/26.
//
import Foundation
import Fluent

struct ChatService {
    
    func send(conversationID: UUID, content: String, on db: any Database) async throws -> Message {
        
        let message = Message(
            id: UUID(),
            conversationID: conversationID,
            content: content,
            role: "user",
            timestamp: Date.now
        )
        
        try await message.save(on: db)
        
        //TODO: implement LLM completion and reply
        return message;
    }
    
    func getMessages(conversationID: UUID, on db: any Database) async throws -> [Message] {
        //TODO Implement
        return []
    }
}
