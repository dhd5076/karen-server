//
//  CreateTaskTable.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/14/26.
//

import Fluent

struct CreateTaskTable: AsyncMigration {
    
    func prepare(on database: any Database) async throws  {
        try await database.schema(KTask.schema)
            .id()
            .field(KTask.FieldKeys.title, .string, .required)
            .field(KTask.FieldKeys.notes, .string, .required)
            .field(KTask.FieldKeys.dueAt, .datetime)
            .field(KTask.FieldKeys.isCompleted, .bool, .required)
            .field(KTask.FieldKeys.completedAt, .datetime)
            .field(KTask.FieldKeys.source, .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(KTask.schema).delete()
    }
}
