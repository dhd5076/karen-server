//
//  VehicleService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Foundation
import Fluent
import KarenShared
import Vapor

struct VehicleService {

    private let entityService = EntityService()
    private let plateRelationshipName = "assigned to vehicle"
    private let inversePlateRelationshipName = "has license plate"

    // MARK: - Make

    func createMake(
        displayName: String,
        on db: any Database
    ) async throws -> VehicleMakeResponse {
        let displayName = try requireNonempty(displayName, field: "Make name")
        let normalizedName = normalizeCatalogName(displayName)

        let existingMake = try await findMakeByNormalizedName(
            normalizedName: normalizedName,
            on: db
        )

        guard existingMake == nil else {
            throw Abort(.conflict, reason: "Vehicle make already exists")
        }

        let make = VehicleMake(
            displayName: displayName,
            normalizedName: normalizedName
        )

        try await make.save(on: db)

        return try makeResponse(make)
    }

    func getAllMakes(on db: any Database) async throws -> [VehicleMakeResponse] {
        try await VehicleMake.query(on: db)
            .sort(\.$displayName)
            .all()
            .map(makeResponse)
    }

    // MARK: - Model

    func createModel(
        makeId: UUID,
        displayName: String,
        on db: any Database
    ) async throws -> VehicleModelResponse {
        _ = try await getMakeById(id: makeId, on: db)

        let displayName = try requireNonempty(displayName, field: "Model name")
        let normalizedName = normalizeCatalogName(displayName)
        let existingModel = try await findModelByNormalizedName(
            makeId: makeId,
            normalizedName: normalizedName,
            on: db
        )

        guard existingModel == nil else {
            throw Abort(.conflict, reason: "Vehicle model already exists for this make")
        }

        let model = VehicleModel(
            makeId: makeId,
            displayName: displayName,
            normalizedName: normalizedName
        )

        try await model.save(on: db)

        return try modelResponse(model)
    }

    func getModels(
        for makeId: UUID,
        on db: any Database
    ) async throws -> [VehicleModelResponse] {
        _ = try await getMakeById(id: makeId, on: db)

        return try await VehicleModel.query(on: db)
            .filter(\.$make.$id == makeId)
            .sort(\.$displayName)
            .all()
            .map(modelResponse)
    }

    // MARK: - Vehicle

    func createVehicle(
        request: VehicleRequest,
        on db: any Database
    ) async throws -> VehicleResponse {
        let values = try normalizedVehicleValues(from: request)

        return try await db.transaction { transaction in
            try await validateMakeAndModel(
                makeId: request.makeId,
                modelId: request.modelId,
                on: transaction
            )

            let entity = try await entityService.createEntity(
                entityType: "vehicle",
                displayName: values.displayName,
                on: transaction
            )

            let vehicle = Vehicle(
                entityId: try entity.requireID(),
                vehicleType: values.vehicleType,
                modelYear: request.modelYear,
                makeId: request.makeId,
                modelId: request.modelId,
                trim: values.trim,
                color: values.color,
                vin: values.vin
            )

            try await vehicle.save(on: transaction)

            return try await getVehicleResponseById(
                id: vehicle.requireID(),
                on: transaction
            )
        }
    }

    func getAllVehicleResponses(
        on db: any Database
    ) async throws -> [VehicleResponse] {
        try await Vehicle.query(on: db)
            .with(\.$entity)
            .with(\.$make)
            .with(\.$model)
            .all()
            .map(vehicleResponse)
            .sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
    }

    func getVehicleResponseById(
        id: UUID,
        on db: any Database
    ) async throws -> VehicleResponse {
        try vehicleResponse(try await getVehicleById(id: id, on: db))
    }

    func updateVehicle(
        id: UUID,
        request: VehicleRequest,
        on db: any Database
    ) async throws -> VehicleResponse {
        let values = try normalizedVehicleValues(from: request)

        return try await db.transaction { transaction in
            let vehicle = try await getVehicleById(id: id, on: transaction)

            try await validateMakeAndModel(
                makeId: request.makeId,
                modelId: request.modelId,
                on: transaction
            )

            _ = try await entityService.updateEntityDisplayName(
                id: vehicle.$entity.id,
                displayName: values.displayName,
                on: transaction
            )

            vehicle.vehicleType = values.vehicleType
            vehicle.modelYear = request.modelYear
            vehicle.$make.id = request.makeId
            vehicle.$model.id = request.modelId
            vehicle.trim = values.trim
            vehicle.color = values.color
            vehicle.vin = values.vin

            try await vehicle.save(on: transaction)

            return try await getVehicleResponseById(id: id, on: transaction)
        }
    }

    // MARK: - License Plate

    func createLicensePlate(
        request: LicensePlateRequest,
        on db: any Database
    ) async throws -> LicensePlateResponse {
        try await db.transaction { transaction in
            try licensePlateResponse(
                try await createLicensePlateRecord(
                    displayNumber: request.displayNumber,
                    jurisdictionCode: request.jurisdictionCode,
                    countryCode: request.countryCode,
                    on: transaction
                )
            )
        }
    }

    func createAndAssignLicensePlate(
        vehicleId: UUID,
        request: LicensePlateRequest,
        on db: any Database
    ) async throws -> VehicleLicensePlateResponse {
        try await db.transaction { transaction in
            let licensePlate = try await createLicensePlateRecord(
                displayNumber: request.displayNumber,
                jurisdictionCode: request.jurisdictionCode,
                countryCode: request.countryCode,
                on: transaction
            )

            return try await assignLicensePlateRecord(
                licensePlate: licensePlate,
                vehicleId: vehicleId,
                validFrom: request.validFrom,
                on: transaction
            )
        }
    }

    func assignLicensePlate(
        licensePlateId: UUID,
        vehicleId: UUID,
        validFrom: Date? = nil,
        on db: any Database
    ) async throws -> VehicleLicensePlateResponse {
        try await db.transaction { transaction in
            let licensePlate = try await getLicensePlateById(
                id: licensePlateId,
                on: transaction
            )

            return try await assignLicensePlateRecord(
                licensePlate: licensePlate,
                vehicleId: vehicleId,
                validFrom: validFrom,
                on: transaction
            )
        }
    }

    func unassignLicensePlate(
        licensePlateId: UUID,
        vehicleId: UUID,
        validUntil: Date = Date(),
        on db: any Database
    ) async throws -> VehicleLicensePlateResponse {
        try await db.transaction { transaction in
            let vehicle = try await getVehicleById(id: vehicleId, on: transaction)
            let licensePlate = try await getLicensePlateById(
                id: licensePlateId,
                on: transaction
            )

            guard let relationshipType = try await findPlateRelationshipType(on: transaction) else {
                throw Abort(.notFound, reason: "License plate assignment doesn't exist")
            }

            guard let relationship = try await EntityRelationship.query(on: transaction)
                .filter(\.$subject.$id == licensePlate.$entity.id)
                .filter(\.$relationshipType.$id == relationshipType.requireID())
                .filter(\.$object.$id == vehicle.$entity.id)
                .filter(\.$validUntil == nil)
                .first()
            else {
                throw Abort(.notFound, reason: "License plate isn't assigned to this vehicle")
            }

            if let validFrom = relationship.validFrom, validUntil < validFrom {
                throw Abort(.badRequest, reason: "Assignment end cannot precede its start")
            }

            relationship.validUntil = validUntil
            try await relationship.save(on: transaction)

            return try licensePlateRelationshipResponse(
                relationship: relationship,
                licensePlate: licensePlate
            )
        }
    }

    func getLicensePlateHistory(
        vehicleId: UUID,
        on db: any Database
    ) async throws -> [VehicleLicensePlateResponse] {
        let vehicle = try await getVehicleById(id: vehicleId, on: db)

        guard let relationshipType = try await findPlateRelationshipType(on: db) else {
            return []
        }

        let relationships = try await EntityRelationship.query(on: db)
            .filter(\.$relationshipType.$id == relationshipType.requireID())
            .filter(\.$object.$id == vehicle.$entity.id)
            .all()

        let entityIds = relationships.map(\.$subject.id)

        guard !entityIds.isEmpty else {
            return []
        }

        let licensePlates = try await LicensePlate.query(on: db)
            .filter(\.$entity.$id ~~ entityIds)
            .with(\.$entity)
            .all()

        let licensePlatesByEntityId = Dictionary(
            uniqueKeysWithValues: licensePlates.map { ($0.$entity.id, $0) }
        )

        return try relationships
            .compactMap { relationship in
                guard let licensePlate = licensePlatesByEntityId[relationship.$subject.id] else {
                    return nil
                }

                return try licensePlateRelationshipResponse(
                    relationship: relationship,
                    licensePlate: licensePlate
                )
            }
            .sorted {
                ($0.validFrom ?? .distantPast) > ($1.validFrom ?? .distantPast)
            }
    }

    func getCurrentLicensePlates(
        vehicleId: UUID,
        on db: any Database
    ) async throws -> [VehicleLicensePlateResponse] {
        try await getLicensePlateHistory(vehicleId: vehicleId, on: db)
            .filter { $0.validUntil == nil }
    }

    func findLicensePlate(
        displayNumber: String,
        jurisdictionCode: String,
        countryCode: String,
        on db: any Database
    ) async throws -> LicensePlate? {
        let normalizedNumber = try normalizePlateNumber(displayNumber)
        let jurisdictionCode = try requireNonempty(
            jurisdictionCode,
            field: "Jurisdiction code"
        ).uppercased()
        let countryCode = try requireNonempty(countryCode, field: "Country code").uppercased()

        return try await LicensePlate.query(on: db)
            .filter(\.$normalizedNumber == normalizedNumber)
            .filter(\.$jurisdictionCode == jurisdictionCode)
            .filter(\.$countryCode == countryCode)
            .with(\.$entity)
            .first()
    }

    // MARK: - Internal Lookups

    func getMakeById(id: UUID, on db: any Database) async throws -> VehicleMake {
        guard let make = try await VehicleMake.find(id, on: db) else {
            throw Abort(.notFound, reason: "Vehicle make with ID doesn't exist")
        }

        return make
    }

    func findMakeByNormalizedName(
        normalizedName: String,
        on db: any Database
    ) async throws -> VehicleMake? {
        try await VehicleMake.query(on: db)
            .filter(\.$normalizedName == normalizedName)
            .first()
    }

    func getModelById(id: UUID, on db: any Database) async throws -> VehicleModel {
        guard let model = try await VehicleModel.query(on: db)
            .filter(\.$id == id)
            .with(\.$make)
            .first()
        else {
            throw Abort(.notFound, reason: "Vehicle model with ID doesn't exist")
        }

        return model
    }

    func findModelByNormalizedName(
        makeId: UUID,
        normalizedName: String,
        on db: any Database
    ) async throws -> VehicleModel? {
        try await VehicleModel.query(on: db)
            .filter(\.$make.$id == makeId)
            .filter(\.$normalizedName == normalizedName)
            .first()
    }

    func getVehicleById(id: UUID, on db: any Database) async throws -> Vehicle {
        guard let vehicle = try await Vehicle.query(on: db)
            .filter(\.$id == id)
            .with(\.$entity)
            .with(\.$make)
            .with(\.$model)
            .first()
        else {
            throw Abort(.notFound, reason: "Vehicle with ID doesn't exist")
        }

        return vehicle
    }

    func getLicensePlateById(
        id: UUID,
        on db: any Database
    ) async throws -> LicensePlate {
        guard let licensePlate = try await LicensePlate.query(on: db)
            .filter(\.$id == id)
            .with(\.$entity)
            .first()
        else {
            throw Abort(.notFound, reason: "License plate with ID doesn't exist")
        }

        return licensePlate
    }

    // MARK: - Internal Writes

    private func createLicensePlateRecord(
        displayNumber: String,
        jurisdictionCode: String,
        countryCode: String,
        on db: any Database
    ) async throws -> LicensePlate {
        let displayNumber = try requireNonempty(displayNumber, field: "License plate number")
        let normalizedNumber = try normalizePlateNumber(displayNumber)
        let jurisdictionCode = try requireNonempty(
            jurisdictionCode,
            field: "Jurisdiction code"
        ).uppercased()
        let countryCode = try requireNonempty(countryCode, field: "Country code").uppercased()

        let existingPlate = try await findLicensePlate(
            displayNumber: normalizedNumber,
            jurisdictionCode: jurisdictionCode,
            countryCode: countryCode,
            on: db
        )

        guard existingPlate == nil else {
            throw Abort(.conflict, reason: "License plate already exists")
        }

        let entity = try await entityService.createEntity(
            entityType: "license_plate",
            displayName: "\(displayNumber) (\(jurisdictionCode))",
            on: db
        )

        let licensePlate = LicensePlate(
            entityId: try entity.requireID(),
            displayNumber: displayNumber,
            normalizedNumber: normalizedNumber,
            jurisdictionCode: jurisdictionCode,
            countryCode: countryCode
        )

        try await licensePlate.save(on: db)

        return licensePlate
    }

    private func assignLicensePlateRecord(
        licensePlate: LicensePlate,
        vehicleId: UUID,
        validFrom: Date?,
        on db: any Database
    ) async throws -> VehicleLicensePlateResponse {
        let vehicle = try await getVehicleById(id: vehicleId, on: db)
        let relationshipType = try await getOrCreatePlateRelationshipType(on: db)
        let relationshipTypeId = try relationshipType.requireID()

        let currentAssignment = try await EntityRelationship.query(on: db)
            .filter(\.$subject.$id == licensePlate.$entity.id)
            .filter(\.$relationshipType.$id == relationshipTypeId)
            .filter(\.$validUntil == nil)
            .first()

        guard currentAssignment == nil else {
            throw Abort(.conflict, reason: "License plate already has a current assignment")
        }

        let relationship = try await entityService.createRelationship(
            subjectId: licensePlate.$entity.id,
            relationshipTypeId: relationshipTypeId,
            objectId: vehicle.$entity.id,
            validFrom: validFrom,
            on: db
        )

        return try licensePlateRelationshipResponse(
            relationship: relationship,
            licensePlate: licensePlate
        )
    }

    private func getOrCreatePlateRelationshipType(
        on db: any Database
    ) async throws -> EntityRelationshipType {
        if let relationshipType = try await findPlateRelationshipType(on: db) {
            return relationshipType
        }

        return try await entityService.createRelationshipType(
            displayName: plateRelationshipName,
            inverseDisplayName: inversePlateRelationshipName,
            on: db
        )
    }

    private func findPlateRelationshipType(
        on db: any Database
    ) async throws -> EntityRelationshipType? {
        try await EntityRelationshipType.query(on: db)
            .filter(\.$displayName == plateRelationshipName)
            .first()
    }

    // MARK: - Validation

    private func validateMakeAndModel(
        makeId: UUID?,
        modelId: UUID?,
        on db: any Database
    ) async throws {
        guard let modelId else {
            if let makeId {
                _ = try await getMakeById(id: makeId, on: db)
            }

            return
        }

        guard let makeId else {
            throw Abort(.badRequest, reason: "A vehicle model requires a make")
        }

        _ = try await getMakeById(id: makeId, on: db)
        let model = try await getModelById(id: modelId, on: db)

        guard model.$make.id == makeId else {
            throw Abort(.badRequest, reason: "Vehicle model doesn't belong to the selected make")
        }
    }

    private func normalizedVehicleValues(
        from request: VehicleRequest
    ) throws -> (
        displayName: String,
        vehicleType: String,
        trim: String?,
        color: String?,
        vin: String?
    ) {
        (
            displayName: try requireNonempty(request.displayName, field: "Display name"),
            vehicleType: try requireNonempty(
                request.vehicleType,
                field: "Vehicle type"
            ).lowercased(),
            trim: normalizeOptional(request.trim),
            color: normalizeOptional(request.color),
            vin: try normalizeVIN(request.vin)
        )
    }

    private func requireNonempty(_ value: String, field: String) throws -> String {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            throw Abort(.badRequest, reason: "\(field) cannot be empty")
        }

        return value
    }

    private func normalizeOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    private func normalizeCatalogName(_ value: String) -> String {
        value.lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func normalizeVIN(_ vin: String?) throws -> String? {
        guard let vin = normalizeOptional(vin) else {
            return nil
        }

        let normalizedVIN = vin.uppercased().filter { $0.isLetter || $0.isNumber }

        guard !normalizedVIN.isEmpty else {
            throw Abort(.badRequest, reason: "VIN must contain letters or numbers")
        }

        return normalizedVIN
    }

    private func normalizePlateNumber(_ plateNumber: String) throws -> String {
        let normalizedNumber = plateNumber.uppercased().filter {
            $0.isLetter || $0.isNumber
        }

        guard !normalizedNumber.isEmpty else {
            throw Abort(.badRequest, reason: "License plate must contain letters or numbers")
        }

        return normalizedNumber
    }

    // MARK: - Responses

    private func makeResponse(_ make: VehicleMake) throws -> VehicleMakeResponse {
        VehicleMakeResponse(
            id: try make.requireID(),
            displayName: make.displayName
        )
    }

    private func modelResponse(_ model: VehicleModel) throws -> VehicleModelResponse {
        VehicleModelResponse(
            id: try model.requireID(),
            makeId: model.$make.id,
            displayName: model.displayName
        )
    }

    private func vehicleResponse(_ vehicle: Vehicle) throws -> VehicleResponse {
        VehicleResponse(
            id: try vehicle.requireID(),
            entityId: vehicle.$entity.id,
            displayName: vehicle.entity.displayName,
            vehicleType: vehicle.vehicleType,
            modelYear: vehicle.modelYear,
            make: try vehicle.make.map(makeResponse),
            model: try vehicle.model.map(modelResponse),
            trim: vehicle.trim,
            color: vehicle.color,
            vin: vehicle.vin
        )
    }

    private func licensePlateResponse(
        _ licensePlate: LicensePlate
    ) throws -> LicensePlateResponse {
        LicensePlateResponse(
            id: try licensePlate.requireID(),
            entityId: licensePlate.$entity.id,
            displayNumber: licensePlate.displayNumber,
            normalizedNumber: licensePlate.normalizedNumber,
            jurisdictionCode: licensePlate.jurisdictionCode,
            countryCode: licensePlate.countryCode
        )
    }

    private func licensePlateRelationshipResponse(
        relationship: EntityRelationship,
        licensePlate: LicensePlate
    ) throws -> VehicleLicensePlateResponse {
        VehicleLicensePlateResponse(
            relationshipId: try relationship.requireID(),
            licensePlate: try licensePlateResponse(licensePlate),
            validFrom: relationship.validFrom,
            validUntil: relationship.validUntil
        )
    }
}
