//
//  Message.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/18/26.
//

import Fluent
import Vapor

final class Message: Model, @unchecked Sendable {
    
    static let schema = "messages"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "conversation_id")
    var conversationID: UUID
    
    @Field(key: "content")
    var content: String
    
    @Field(key: "role")
    var role: String
    
    @Field(key: "timestamp")
    var timestamp: Date
    
    init () { }
    
    init(
        id: UUID? = nil,
        conversationID: UUID,
        content: String,
        role: String,
        timestamp: Date
    ) {
        self.id = id
        self.conversationID = conversationID
        self.content = content
        self.role = role
        self.timestamp = timestamp
    }
}
