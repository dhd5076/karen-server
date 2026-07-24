//
//  CreateEntityTables.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Fluent

struct CreateEntityTables: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database.schema(Entity.schema)
            .id()
            .field(Entity.FieldKeys.entityType, .string, .required)
            .field(Entity.FieldKeys.displayName, .string, .required)
            .create()
        
        try await database.schema(EntityRelationshipType.schema)
            .id()
            .field(EntityRelationshipType.FieldKeys.displayName, .string, .required)
            .field(EntityRelationshipType.FieldKeys.inverseDisplayName, .string, .required)
            .unique(on: EntityRelationshipType.FieldKeys.displayName)
            .create()
        
        try await database.schema(EntityRelationship.schema)
            .id()
            .field(
                EntityRelationship.FieldKeys.subject,
                .uuid,
                .required,
                .references(Entity.schema, "id", onDelete: .restrict)
            )
            .field(
                EntityRelationship.FieldKeys.relationshipType,
                .uuid,
                .required,
                .references(EntityRelationshipType.schema, "id", onDelete: .restrict)
            )
            .field(
                EntityRelationship.FieldKeys.object,
                .uuid,
                .required,
                .references(Entity.schema, "id", onDelete: .restrict)
            )
            .field(EntityRelationship.FieldKeys.validFrom, .datetime)
            .field(EntityRelationship.FieldKeys.validUntil, .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(EntityRelationship.schema).delete()
        try await database.schema(EntityRelationshipType.schema).delete()
        try await database.schema(Entity.schema).delete()
    }
}
