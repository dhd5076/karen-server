//
//  ChatController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/17/26.
//

import Vapor

struct ChatController {
    let chatService = ChatService()
    
    func send(_ req: Request) async throws -> Message {
        let data = try req.content.decode(SendMessageRequest.self)
        
        
        return try await chatService.send(
            conversationID: data.conversationID,
            content: data.content,
            on: req.db
        )
        
    }
    
    func getConversation(_ req: Request) async throws -> [Message] {
        
        guard let conversationID = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        return try await chatService.getMessages(
            conversationID: conversationID,
            on: req.db
        )
    }
}
