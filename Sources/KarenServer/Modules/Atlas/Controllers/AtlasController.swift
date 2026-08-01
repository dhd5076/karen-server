//
//  AtlasController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 8/1/26.
//

import KarenKit
import Vapor

struct AtlasController: RouteCollection {

    private let atlasService = AtlasService()

    func boot(routes: any RoutesBuilder) throws {
        routes.get("entities", use: getEntities)
        routes.post("entities", use: createEntity)
        routes.get("entities", .parameter("id"), use: getEntity)
        routes.patch("entities", .parameter("id"), use: updateEntity)
        routes.get(
            "entities",
            .parameter("id"),
            "attributes",
            use: getAttributes
        )
        routes.get(
            "entities",
            .parameter("id"),
            "attributes",
            .parameter("key"),
            use: getAttribute
        )
        routes.put(
            "entities",
            .parameter("id"),
            "attributes",
            .parameter("key"),
            use: setAttribute
        )
        routes.get(
            "entities",
            .parameter("id"),
            "relationships",
            use: getEntityRelationships
        )

        routes.get("relationships", use: getRelationships)
        routes.post("relationships", use: createRelationship)
        routes.get(
            "relationships",
            .parameter("id"),
            use: getRelationship
        )
        routes.post(
            "relationships",
            .parameter("id"),
            "end",
            use: endRelationship
        )
    }

    private func getEntities(req: Request) async throws -> [AtlasEntity] {
        let query = try req.query.decode(EntityListQuery.self)

        return try await atlasService.getEntities(
            ofType: query.type.map(EntityType.init(rawValue:))
        )
    }

    private func createEntity(req: Request) async throws -> AtlasEntity {
        try await atlasService.createEntity(
            request: req.content.decode(CreateAtlasEntityRequest.self)
        )
    }

    private func getEntity(req: Request) async throws -> AtlasEntity {
        try await atlasService.getEntity(
            id: req.parameters.require("id", as: UUID.self)
        )
    }

    private func updateEntity(req: Request) async throws -> AtlasEntity {
        try await atlasService.updateEntity(
            id: req.parameters.require("id", as: UUID.self),
            request: req.content.decode(UpdateAtlasEntityRequest.self)
        )
    }

    private func getAttributes(req: Request) async throws -> [AtlasAttribute] {
        try await atlasService.getAttributes(
            entityId: req.parameters.require("id", as: UUID.self)
        )
    }

    private func getAttribute(req: Request) async throws -> AtlasAttribute {
        try await atlasService.getAttribute(
            entityId: req.parameters.require("id", as: UUID.self),
            key: AttributeKey(
                rawValue: req.parameters.require("key")
            )
        )
    }

    private func setAttribute(req: Request) async throws -> AtlasAttribute {
        try await atlasService.setAttribute(
            entityId: req.parameters.require("id", as: UUID.self),
            key: AttributeKey(
                rawValue: req.parameters.require("key")
            ),
            request: req.content.decode(SetAtlasAttributeRequest.self)
        )
    }

    private func getEntityRelationships(
        req: Request
    ) async throws -> [AtlasRelationship] {
        let query = try req.query.decode(EntityRelationshipListQuery.self)

        return try await atlasService.getRelationships(
            entityId: req.parameters.require("id", as: UUID.self),
            includeEnded: query.includeEnded ?? false
        )
    }

    private func getRelationships(
        req: Request
    ) async throws -> [AtlasRelationship] {
        let query = try req.query.decode(RelationshipListQuery.self)

        return try await atlasService.getRelationships(
            subject: query.subject,
            object: query.object,
            type: query.type.map(RelationshipType.init(rawValue:)),
            includeEnded: query.includeEnded ?? false
        )
    }

    private func createRelationship(
        req: Request
    ) async throws -> AtlasRelationship {
        try await atlasService.createRelationship(
            request: req.content.decode(
                CreateAtlasRelationshipRequest.self
            )
        )
    }

    private func getRelationship(req: Request) async throws -> AtlasRelationship {
        try await atlasService.getRelationship(
            id: req.parameters.require("id", as: UUID.self)
        )
    }

    private func endRelationship(req: Request) async throws -> AtlasRelationship {
        try await atlasService.endRelationship(
            id: req.parameters.require("id", as: UUID.self),
            request: req.content.decode(EndAtlasRelationshipRequest.self)
        )
    }
}

private struct EntityListQuery: Content {
    let type: String?
}

private struct EntityRelationshipListQuery: Content {
    let includeEnded: Bool?
}

private struct RelationshipListQuery: Content {
    let subject: UUID?
    let object: UUID?
    let type: String?
    let includeEnded: Bool?
}
