//
//  CreatePantry.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Fluent

struct CreatePantryTables: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database.schema(Pantry.schema)
            .id()
            .field(Pantry.FieldKeys.name, .string, .required)
            .create()
        
        try await database.schema(PantryProduct.schema)
            .id()
            .field(PantryProduct.FieldKeys.name, .string, .required)
            .field(PantryProduct.FieldKeys.unit, .string, .required)
            .field(PantryProduct.FieldKeys.proteinPerUnit, .double, .required)
            .field(PantryProduct.FieldKeys.carbsPerUnit, .double, .required)
            .field(PantryProduct.FieldKeys.fatPerUnit, .double, .required)
            .field(PantryProduct.FieldKeys.shelfLife, .int, .required)
            .create()
        
        try await database.schema(PantryBatch.schema)
            .id()
            .field(PantryBatch.FieldKeys.pantry, .uuid, .required, .references(Pantry.schema, "id"))
            .field(PantryBatch.FieldKeys.product, .uuid, .required, .references(PantryProduct.schema,"id"))
            .field(PantryBatch.FieldKeys.quantity, .double, .required)
            .field(PantryBatch.FieldKeys.source, .string, .required)
            .field(PantryBatch.FieldKeys.acquiredAt, .datetime, .required)
            .create()
        
        try await database.schema(PantryTransaction.schema)
            .id()
            .field(PantryTransaction.FieldKeys.type, .string, .required)
            .field(PantryTransaction.FieldKeys.product, .uuid, .required, .references(PantryProduct.schema, "id"))
            .field(PantryTransaction.FieldKeys.batch, .uuid, .references(PantryBatch.schema, "id"))
            .field(PantryTransaction.FieldKeys.fromPantry, .uuid, .references(Pantry.schema, "id"))
            .field(PantryTransaction.FieldKeys.toPantry, .uuid, .references(Pantry.schema, "id"))
            .field(PantryTransaction.FieldKeys.quantity, .double, .required)
            .field(PantryTransaction.FieldKeys.createdAt, .datetime, .required)
            .field(PantryTransaction.FieldKeys.note, .string)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(PantryTransaction.schema).delete()
        try await database.schema(PantryBatch.schema).delete()
        try await database.schema(PantryProduct.schema).delete()
        try await database.schema(Pantry.schema).delete()
    }
}
