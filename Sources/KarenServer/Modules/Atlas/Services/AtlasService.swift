//
//  AtlasService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 8/1/26.
//

import Foundation
import KarenAtlas
import KarenKit
import Vapor

struct AtlasService: Sendable {
    func getEntities(
        ofType type: EntityType? = nil
    ) async throws -> [AtlasEntity] {
        try await Atlas.entities(ofType: type).map(makeResponse)
    }

    func getEntity(id: UUID) async throws -> AtlasEntity {
        makeResponse(from: try await requireEntity(id: id))
    }

    func createEntity(
        request: CreateAtlasEntityRequest
    ) async throws -> AtlasEntity {
        let type = EntityType(
            rawValue: try requireNonempty(
                request.type.rawValue,
                field: "Entity type"
            )
        )
        let displayName = try requireNonempty(
            request.displayName,
            field: "Display name"
        )

        return makeResponse(
            from: try await Atlas.createEntity(type, displayName)
        )
    }

    func updateEntity(
        id: UUID,
        request: UpdateAtlasEntityRequest
    ) async throws -> AtlasEntity {
        let entity = try await requireEntity(id: id)
        let displayName = try requireNonempty(
            request.displayName,
            field: "Display name"
        )

        return makeResponse(
            from: try await entity.updateDisplayName(displayName)
        )
    }

    func getAttributes(entityId: UUID) async throws -> [AtlasAttribute] {
        let entity = try await requireEntity(id: entityId)

        return try await entity.attributeValues().sorted {
            $0.key.rawValue < $1.key.rawValue
        }
    }

    func getAttribute(
        entityId: UUID,
        key: AttributeKey
    ) async throws -> AtlasAttribute {
        let entity = try await requireEntity(id: entityId)

        guard let attribute = try await entity.attributeValue(key) else {
            throw Abort(.notFound, reason: "Entity attribute doesn't exist")
        }

        return attribute
    }

    func setAttribute(
        entityId: UUID,
        key: AttributeKey,
        request: SetAtlasAttributeRequest
    ) async throws -> AtlasAttribute {
        let entity = try await requireEntity(id: entityId)
        let key = AttributeKey(
            rawValue: try requireNonempty(
                key.rawValue,
                field: "Attribute key"
            )
        )
        let valueType = try requireNonempty(
            request.valueType ?? "string",
            field: "Attribute value type"
        )

        try await entity.setAttribute(
            key,
            to: request.value,
            valueType: valueType
        )

        return AtlasAttribute(
            key: key,
            value: request.value,
            valueType: valueType
        )
    }

    func getRelationships(
        subject: UUID? = nil,
        object: UUID? = nil,
        type: RelationshipType? = nil,
        includeEnded: Bool = false
    ) async throws -> [AtlasRelationship] {
        try await Atlas.relationships(
            subject: subject,
            object: object,
            type: type,
            includeEnded: includeEnded
        ).map(makeResponse)
    }

    func getRelationships(
        entityId: UUID,
        includeEnded: Bool = false
    ) async throws -> [AtlasRelationship] {
        let entity = try await requireEntity(id: entityId)

        return try await entity.relationships(
            includeEnded: includeEnded
        ).map(makeResponse)
    }

    func getRelationship(id: UUID) async throws -> AtlasRelationship {
        makeResponse(from: try await requireRelationship(id: id))
    }

    func createRelationship(
        request: CreateAtlasRelationshipRequest
    ) async throws -> AtlasRelationship {
        let subject = try await requireEntity(id: request.subject)
        let object = try await requireEntity(id: request.object)
        let type = RelationshipType(
            rawValue: try requireNonempty(
                request.type.rawValue,
                field: "Relationship type"
            )
        )

        return makeResponse(
            from: try await subject.relate(
                to: object,
                as: type,
                validFrom: request.validFrom
            )
        )
    }

    func endRelationship(
        id: UUID,
        request: EndAtlasRelationshipRequest
    ) async throws -> AtlasRelationship {
        let relationship = try await requireRelationship(id: id)

        guard relationship.validUntil == nil else {
            throw Abort(.conflict, reason: "Relationship has already ended")
        }

        let validUntil = request.validUntil ?? Date()

        if let validFrom = relationship.validFrom, validUntil < validFrom {
            throw Abort(
                .badRequest,
                reason: "Relationship end cannot precede its start"
            )
        }

        return makeResponse(
            from: try await relationship.end(at: validUntil)
        )
    }

    private func requireEntity(id: UUID) async throws -> Entity {
        do {
            return try await Atlas.entity(id: id)
        } catch AtlasError.entityNotFound {
            throw Abort(.notFound, reason: "Entity with ID doesn't exist")
        }
    }

    private func requireRelationship(id: UUID) async throws -> Relationship {
        do {
            return try await Atlas.relationship(id: id)
        } catch AtlasError.relationshipNotFound {
            throw Abort(.notFound, reason: "Relationship with ID doesn't exist")
        }
    }

    private func makeResponse(from entity: Entity) -> AtlasEntity {
        AtlasEntity(
            id: entity.id,
            type: entity.type,
            displayName: entity.displayName
        )
    }

    private func makeResponse(
        from relationship: Relationship
    ) -> AtlasRelationship {
        AtlasRelationship(
            id: relationship.id,
            type: relationship.type,
            subject: relationship.subject,
            object: relationship.object,
            validFrom: relationship.validFrom,
            validUntil: relationship.validUntil
        )
    }

    private func requireNonempty(
        _ value: String,
        field: String
    ) throws -> String {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            throw Abort(.badRequest, reason: "\(field) cannot be empty")
        }

        return value
    }
}
