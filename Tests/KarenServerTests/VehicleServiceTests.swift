import Fluent
import FluentSQLiteDriver
import KarenAtlas
import KarenKit
import Testing
import Vapor
@testable import KarenServer

@Suite("KarenServer Atlas integration", .serialized)
struct KarenServerAtlasTests {
    @Test("Persists and updates Atlas-backed people")
    func peopleLifecycle() async throws {
        try await withTestDatabase {
            let service = PeopleService()
            let complete = try await service.createPerson(
                request: PersonRequest(
                    firstName: "  Dylan ",
                    middleName: "James",
                    lastName: "Dunn"
                )
            )
            let firstNameOnly = try await service.createPerson(
                request: PersonRequest(firstName: "Alex")
            )

            #expect(complete.displayName == "Dylan James Dunn")
            #expect(complete.firstName == "Dylan")
            #expect(complete.middleName == "James")
            #expect(complete.lastName == "Dunn")
            #expect(firstNameOnly.displayName == "Alex")
            #expect(firstNameOnly.middleName == nil)
            #expect(firstNameOnly.lastName == nil)

            let fetched = try await service.getPersonById(id: complete.id)
            #expect(fetched.id == complete.id)

            let updated = try await service.updatePerson(
                id: complete.id,
                request: PersonRequest(
                    firstName: "Dylan",
                    middleName: " ",
                    lastName: nil
                )
            )
            #expect(updated.displayName == "Dylan")
            #expect(updated.middleName == nil)
            #expect(updated.lastName == nil)

            let entity = try await Atlas.entity(id: complete.id)
            #expect(try await entity.attribute(.middleName) == nil)
            #expect(try await entity.attribute(.lastName) == nil)

            let people = try await service.getAll()
            #expect(people.map(\.displayName) == ["Alex", "Dylan"])

            let searchResults = try await service.searchByName(query: "dYl")
            #expect(searchResults.map(\.id) == [complete.id])
        }
    }

    @Test("Rejects missing and non-Person entity IDs")
    func rejectsInvalidPersonIds() async throws {
        try await withTestDatabase {
            let service = PeopleService()

            await #expect(throws: Abort.self) {
                _ = try await service.getPersonById(id: UUID())
            }

            let vehicle = try await Atlas.createEntity(.vehicle, "Not a Person")
            await #expect(throws: Abort.self) {
                _ = try await service.getPersonById(id: vehicle.id)
            }

            await #expect(throws: Abort.self) {
                _ = try await service.createPerson(
                    request: PersonRequest(firstName: "  ")
                )
            }
        }
    }

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
