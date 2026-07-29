import Fluent
import FluentSQLiteDriver
import KarenAtlas
import KarenKit
import Testing
import Vapor
@testable import KarenServer

@Suite("Atlas-backed Vehicle service", .serialized)
struct VehicleServiceTests {
    @Test("Persists a complete vehicle and license plate lifecycle")
    func vehicleLifecycle() async throws {
        try await withTestDatabase {
            let service = VehicleService()
            let make = try await service.createMake(displayName: "Nissan")
            let model = try await service.createModel(
                makeId: make.id,
                displayName: "Frontier"
            )
            let vehicle = try await service.createVehicle(
                request: VehicleRequest(
                    displayName: "My Truck",
                    vehicleType: "truck",
                    modelYear: 2021,
                    makeId: make.id,
                    modelId: model.id,
                    trim: "SV",
                    color: "Blue",
                    vin: "1N6ED1"
                )
            )

            #expect(vehicle.id == vehicle.entityId)
            #expect(vehicle.make?.id == make.id)
            #expect(vehicle.model?.id == model.id)
            #expect(vehicle.modelYear == 2021)
            #expect(vehicle.vin == "1N6ED1")

            let updated = try await service.updateVehicle(
                id: vehicle.id,
                request: VehicleRequest(
                    displayName: "Frontier",
                    vehicleType: "truck",
                    modelYear: 2021,
                    makeId: make.id,
                    modelId: model.id,
                    color: "Gray"
                )
            )

            #expect(updated.displayName == "Frontier")
            #expect(updated.trim == nil)
            #expect(updated.color == "Gray")
            #expect(updated.vin == nil)

            let assignment = try await service.createAndAssignLicensePlate(
                vehicleId: vehicle.id,
                request: LicensePlateRequest(
                    displayNumber: "ABC 123",
                    jurisdictionCode: "NY",
                    countryCode: "US"
                )
            )

            #expect(assignment.licensePlate.normalizedNumber == "ABC123")
            #expect(assignment.validUntil == nil)

            let endedAssignment = try await service.unassignLicensePlate(
                licensePlateId: assignment.licensePlate.id,
                vehicleId: vehicle.id
            )
            let history = try await service.getLicensePlateHistory(
                vehicleId: vehicle.id
            )

            #expect(endedAssignment.validUntil != nil)
            #expect(history.count == 1)
            #expect(history[0].validUntil != nil)
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
