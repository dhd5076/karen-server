//
//  CreatePeople.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/25/26.
//

import Fluent

struct CreatePeople: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database.schema("people")
            .id()
            .field("firstname", .string, .required)
            .field("middlename", .string, .required)
            .field("lastname", .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("people").delete()
    }
}
