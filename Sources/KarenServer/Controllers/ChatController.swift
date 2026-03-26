//
//  ChatController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/17/26.
//

import Vapor

struct ChatController {
    //TODO: make global
    let chatService = ChatService()
    
    func send(req: Request) async throws -> SendChatResponse {
        let data = try req.content.decode(SendChatRequest.self)
        
        
        let responseMessage = try await chatService.send(
            conversationID: data.conversationID,
            content: data.content,
            on: req.db
        )
        
        return SendChatResponse(
            content: responseMessage.content
        )
        
    }
    
    func getConversation(_ req: Request) async throws -> GetConversationResponse {
        
        guard let conversationID = req.parameters.get("conversationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let messages = try await chatService.getMessages(
            conversationID: conversationID,
            on: req.db
        )
        
        let messageResponses = try messages.map(MessageResponse.init)
        
        return GetConversationResponse(
            messages: messageResponses
        )
    }
}

