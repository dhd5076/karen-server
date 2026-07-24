//
//  EntityService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Foundation
import Fluent
import Vapor

struct EntityService {
    
    // MARK: - Entity
    
    func createEntity(
        entityType: String,
        displayName: String,
        on db: any Database
    ) async throws -> Entity {
        let entityType = try requireNonempty(entityType, field: "Entity type")
        let displayName = try requireNonempty(displayName, field: "Display name")
        
        let entity = Entity()
        entity.entityType = entityType
        entity.displayName = displayName
        
        try await entity.save(on: db)
        
        return entity
    }
    
    func getEntityById(id: UUID, on db: any Database) async throws -> Entity {
        guard let entity = try await Entity.find(id, on: db) else {
            throw Abort(.notFound, reason: "Entity with ID doesn't exist")
        }
        
        return entity
    }
    
    func getAllEntities(on db: any Database) async throws -> [Entity] {
        try await Entity.query(on: db).all()
    }
    
    func getEntitiesByType(
        entityType: String,
        on db: any Database
    ) async throws -> [Entity] {
        let entityType = try requireNonempty(entityType, field: "Entity type")
        
        return try await Entity.query(on: db)
            .filter(\.$entityType == entityType)
            .all()
    }
    
    func updateEntityDisplayName(
        id: UUID,
        displayName: String,
        on db: any Database
    ) async throws -> Entity {
        let entity = try await getEntityById(id: id, on: db)
        entity.displayName = try requireNonempty(displayName, field: "Display name")
        
        try await entity.save(on: db)
        
        return entity
    }
    
    // MARK: - Relationship Type
    
    func createRelationshipType(
        displayName: String,
        inverseDisplayName: String,
        on db: any Database
    ) async throws -> EntityRelationshipType {
        let displayName = try requireNonempty(displayName, field: "Display name")
        let inverseDisplayName = try requireNonempty(
            inverseDisplayName,
            field: "Inverse display name"
        )
        
        let existingType = try await EntityRelationshipType.query(on: db)
            .filter(\.$displayName == displayName)
            .first()
        
        guard existingType == nil else {
            throw Abort(.conflict, reason: "Relationship type already exists")
        }
        
        let relationshipType = EntityRelationshipType(
            displayName: displayName,
            inverseDisplayName: inverseDisplayName
        )
        
        try await relationshipType.save(on: db)
        
        return relationshipType
    }
    
    func getRelationshipTypeById(
        id: UUID,
        on db: any Database
    ) async throws -> EntityRelationshipType {
        guard let relationshipType = try await EntityRelationshipType.find(id, on: db) else {
            throw Abort(.notFound, reason: "Relationship type with ID doesn't exist")
        }
        
        return relationshipType
    }
    
    func getAllRelationshipTypes(
        on db: any Database
    ) async throws -> [EntityRelationshipType] {
        try await EntityRelationshipType.query(on: db).all()
    }
    
    // MARK: - Relationship
    
    func createRelationship(
        subjectId: UUID,
        relationshipTypeId: UUID,
        objectId: UUID,
        validFrom: Date? = nil,
        validUntil: Date? = nil,
        on db: any Database
    ) async throws -> EntityRelationship {
        guard subjectId != objectId else {
            throw Abort(.badRequest, reason: "An entity cannot relate to itself")
        }
        
        if let validFrom, let validUntil, validUntil < validFrom {
            throw Abort(.badRequest, reason: "Relationship end cannot precede its start")
        }
        
        _ = try await getEntityById(id: subjectId, on: db)
        _ = try await getEntityById(id: objectId, on: db)
        _ = try await getRelationshipTypeById(id: relationshipTypeId, on: db)
        
        let relationship = EntityRelationship(
            subject: subjectId,
            relationshipType: relationshipTypeId,
            object: objectId,
            validFrom: validFrom,
            validUntil: validUntil
        )
        
        try await relationship.save(on: db)
        
        return relationship
    }
    
    func getRelationshipById(
        id: UUID,
        on db: any Database
    ) async throws -> EntityRelationship {
        guard let relationship = try await EntityRelationship.find(id, on: db) else {
            throw Abort(.notFound, reason: "Entity relationship with ID doesn't exist")
        }
        
        return relationship
    }
    
    func getRelationships(
        for entityId: UUID,
        on db: any Database
    ) async throws -> [EntityRelationship] {
        _ = try await getEntityById(id: entityId, on: db)
        
        return try await EntityRelationship.query(on: db)
            .group(.or) { relationships in
                relationships
                    .filter(\.$subject.$id == entityId)
                    .filter(\.$object.$id == entityId)
            }
            .with(\.$subject)
            .with(\.$relationshipType)
            .with(\.$object)
            .all()
    }
    
    func endRelationship(
        id: UUID,
        at validUntil: Date = Date(),
        on db: any Database
    ) async throws -> EntityRelationship {
        let relationship = try await getRelationshipById(id: id, on: db)
        
        guard relationship.validUntil == nil else {
            throw Abort(.conflict, reason: "Relationship has already ended")
        }
        
        if let validFrom = relationship.validFrom, validUntil < validFrom {
            throw Abort(.badRequest, reason: "Relationship end cannot precede its start")
        }
        
        relationship.validUntil = validUntil
        try await relationship.save(on: db)
        
        return relationship
    }
    
    private func requireNonempty(_ value: String, field: String) throws -> String {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !value.isEmpty else {
            throw Abort(.badRequest, reason: "\(field) cannot be empty")
        }
        
        return value
    }
}
