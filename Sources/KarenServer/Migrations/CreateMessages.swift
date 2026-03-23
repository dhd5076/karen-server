//
//  CreateMessages.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/18/26.
//

import Fluent

struct CreateMessages: AsyncMigration {
    func prepare(on database: any Database) async throws {

        try await database.schema("messages")
            .id()
            .field("conversation_id", .uuid, .required)
            .field("content", .string, .required)
            .field("role", .string, .required)
            .field("timestamp", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("messages").delete()
    }
}

