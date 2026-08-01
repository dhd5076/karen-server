import Fluent
import FluentSQLiteDriver
import KarenAtlas
import KarenKit
import Testing
import Vapor
@testable import KarenServer

extension KarenServerAtlasTests {
    @Test("Registers only the non-destructive Atlas route surface")
    func atlasRoutes() async throws {
        let app = try await Application.make(.testing)

        do {
            try app.register(collection: AtlasRoutes())
            let atlasRoutes = app.routes.all.filter {
                $0.path.first?.description == AtlasModule.route
            }

            #expect(atlasRoutes.count == 12)
            #expect(atlasRoutes.allSatisfy { $0.method != .DELETE })
            try await app.asyncShutdown()
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
    }

    @Test("Manages the non-destructive Atlas lifecycle")
    func atlasLifecycle() async throws {
        try await withTestDatabase {
            let service = AtlasService()
            let vehicle = try await service.createEntity(
                request: CreateAtlasEntityRequest(
                    type: .vehicle,
                    displayName: "My Truck"
                )
            )
            let owner = try await service.createEntity(
                request: CreateAtlasEntityRequest(
                    type: EntityType(rawValue: "person"),
                    displayName: "Dylan"
                )
            )

            let entities = try await service.getEntities(ofType: .vehicle)
            let updatedVehicle = try await service.updateEntity(
                id: vehicle.id,
                request: UpdateAtlasEntityRequest(displayName: "Frontier")
            )
            let attribute = try await service.setAttribute(
                entityId: vehicle.id,
                key: .color,
                request: SetAtlasAttributeRequest(
                    value: "blue",
                    valueType: "color-name"
                )
            )
            let fetchedAttribute = try await service.getAttribute(
                entityId: vehicle.id,
                key: .color
            )
            let attributes = try await service.getAttributes(
                entityId: vehicle.id
            )

            let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
            let relationship = try await service.createRelationship(
                request: CreateAtlasRelationshipRequest(
                    subject: owner.id,
                    type: RelationshipType(rawValue: "owns"),
                    object: vehicle.id,
                    validFrom: startedAt
                )
            )
            let fetchedRelationship = try await service.getRelationship(
                id: relationship.id
            )
            let ownerRelationships = try await service.getRelationships(
                subject: owner.id,
                type: RelationshipType(rawValue: "owns")
            )
            let vehicleRelationships = try await service.getRelationships(
                entityId: vehicle.id
            )
            let endedAt = startedAt.addingTimeInterval(3_600)
            let endedRelationship = try await service.endRelationship(
                id: relationship.id,
                request: EndAtlasRelationshipRequest(validUntil: endedAt)
            )
            let activeRelationships = try await service.getRelationships(
                subject: owner.id
            )
            let relationshipHistory = try await service.getRelationships(
                subject: owner.id,
                includeEnded: true
            )

            #expect(entities.map(\.id) == [vehicle.id])
            #expect(updatedVehicle.displayName == "Frontier")
            #expect(attribute.value == "blue")
            #expect(attribute.valueType == "color-name")
            #expect(fetchedAttribute.key == .color)
            #expect(attributes.count == 1)
            #expect(fetchedRelationship.id == relationship.id)
            #expect(ownerRelationships.map(\.id) == [relationship.id])
            #expect(vehicleRelationships.map(\.id) == [relationship.id])
            #expect(endedRelationship.validUntil == endedAt)
            #expect(activeRelationships.isEmpty)
            #expect(relationshipHistory.map(\.id) == [relationship.id])
        }
    }

    @Test("Returns not found for an unknown entity ID")
    func missingEntity() async throws {
        try await withTestDatabase {
            let service = AtlasService()

            do {
                _ = try await service.getEntity(id: UUID())
                Issue.record("Expected the service to throw Abort.notFound")
            } catch let error as Abort {
                #expect(error.status == .notFound)
            }
        }
    }

    private func withTestDatabase(
        _ operation: () async throws -> Void
    ) async throws {
        let app = try await Application.make(.testing)
        app.databases.use(.sqlite(.memory), as: .sqlite)
        app.migrations.add(CreateAtlasTables())

        do {
            try await app.autoMigrate()
            await Atlas.configure(database: app.db)
            try await operation()
            try await app.asyncShutdown()
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
    }
}
