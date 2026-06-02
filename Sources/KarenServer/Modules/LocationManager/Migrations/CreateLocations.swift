//
//  CreateLocationLog.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/17/26.
//

import Fluent

struct CreateLocations: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database.schema("locations")
            .id()
            .field("type", .string, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("recorded_at", .datetime, .required)
            .field("metadata", .json, .required, .sql(.default("{}")))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("locations").delete()
    }
}
