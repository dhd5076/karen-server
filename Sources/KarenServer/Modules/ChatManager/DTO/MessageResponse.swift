//
//  MessageResponse.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/24/26.
//
import Vapor

struct MessageResponse: Content {
    let id: UUID
    let conversationID: UUID
    let content: String
    let role: String
    let timestamp: Date
    
    init(message: Message) throws {
        guard let id = message.id else {
            throw Abort(.internalServerError)
        }
        self.id = id
        self.conversationID = message.conversationID
        self.content = message.content
        self.role = message.role
        self.timestamp = message.timestamp
    }
}
