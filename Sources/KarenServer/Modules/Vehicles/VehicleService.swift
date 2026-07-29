//
//  VehicleService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Foundation
import KarenAtlas
import KarenKit
import Vapor

struct VehicleService: Sendable {

    // MARK: - Make

    func createMake(displayName: String) async throws -> VehicleMake {
        let displayName = try requireNonempty(displayName, field: "Make name")
        let normalizedName = normalizeCatalogName(displayName)

        return try await Atlas.transaction {
            guard try await findEntity(
                type: .vehicleMake,
                attribute: .normalizedName,
                value: normalizedName
            ) == nil else {
                throw Abort(.conflict, reason: "Vehicle make already exists")
            }

            let make = try await Atlas.createEntity(.vehicleMake, displayName)
            try await make.setAttribute(
                .normalizedName,
                to: normalizedName
            )

            return hydrateVehicleMake(from: make)
        }
    }

    func getAllMakes() async throws -> [VehicleMake] {
        try await Atlas.entities(ofType: .vehicleMake)
            .map { hydrateVehicleMake(from: $0) }
            .sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
    }

    // MARK: - Model

    func createModel(
        makeId: UUID,
        displayName: String
    ) async throws -> VehicleModel {
        let displayName = try requireNonempty(displayName, field: "Model name")
        let normalizedName = normalizeCatalogName(displayName)

        return try await Atlas.transaction {
            let make = try await requireEntity(
                id: makeId,
                type: .vehicleMake,
                label: "Vehicle make"
            )

            let existingModels = try await getModelEntities(for: makeId)
            for model in existingModels where
                try await model.attribute(.normalizedName)
                    == normalizedName {
                throw Abort(
                    .conflict,
                    reason: "Vehicle model already exists for this make"
                )
            }

            let model = try await Atlas.createEntity(.vehicleModel, displayName)
            try await model.setAttribute(
                .normalizedName,
                to: normalizedName
            )
            try await model.relate(
                to: make,
                as: .modelMake
            )

            return VehicleModel(
                id: model.id,
                makeId: make.id,
                displayName: model.displayName
            )
        }
    }

    func getModels(for makeId: UUID) async throws -> [VehicleModel] {
        _ = try await requireEntity(
            id: makeId,
            type: .vehicleMake,
            label: "Vehicle make"
        )

        return try await getModelEntities(for: makeId)
            .map {
                VehicleModel(
                    id: $0.id,
                    makeId: makeId,
                    displayName: $0.displayName
                )
            }
            .sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
    }

    // MARK: - Vehicle

    func createVehicle(request: VehicleRequest) async throws -> Vehicle {
        let values = try normalizedVehicleValues(from: request)

        return try await Atlas.transaction {
            try await validateMakeAndModel(
                makeId: request.makeId,
                modelId: request.modelId
            )
            try await validateUniqueVIN(values.vin)

            let vehicle = try await Atlas.createEntity(.vehicle, values.displayName)

            try await applyVehicleRequest(
                on: vehicle,
                request: request,
                normalizedValues: values
            )
            try await replaceRelationship(
                from: vehicle,
                type: .vehicleMake,
                targetId: request.makeId
            )
            try await replaceRelationship(
                from: vehicle,
                type: .vehicleModel,
                targetId: request.modelId
            )

            return try await hydrateVehicle(from: vehicle)
        }
    }

    func getAllVehicles() async throws -> [Vehicle] {
        var vehicles: [Vehicle] = []

        for vehicle in try await Atlas.entities(
            ofType: .vehicle
        ) {
            vehicles.append(try await hydrateVehicle(from: vehicle))
        }

        return vehicles.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    func getVehicleById(id: UUID) async throws -> Vehicle {
        try await hydrateVehicle(
            from: try await requireEntity(
                id: id,
                type: .vehicle,
                label: "Vehicle"
            )
        )
    }

    func updateVehicle(
        id: UUID,
        request: VehicleRequest
    ) async throws -> Vehicle {
        let values = try normalizedVehicleValues(from: request)

        return try await Atlas.transaction {
            let vehicle = try await requireEntity(
                id: id,
                type: .vehicle,
                label: "Vehicle"
            )

            try await validateMakeAndModel(
                makeId: request.makeId,
                modelId: request.modelId
            )
            try await validateUniqueVIN(values.vin, excluding: id)

            let updatedVehicle = try await vehicle.updateDisplayName(values.displayName)
            try await applyVehicleRequest(
                on: updatedVehicle,
                request: request,
                normalizedValues: values
            )
            try await replaceRelationship(
                from: updatedVehicle,
                type: .vehicleMake,
                targetId: request.makeId
            )
            try await replaceRelationship(
                from: updatedVehicle,
                type: .vehicleModel,
                targetId: request.modelId
            )

            return try await hydrateVehicle(from: updatedVehicle)
        }
    }

    // MARK: - License Plate

    func createAndAssignLicensePlate(
        vehicleId: UUID,
        request: LicensePlateRequest
    ) async throws -> VehicleLicensePlateAssignment {
        try await Atlas.transaction {
            let licensePlate = try await createLicensePlate(request: request)

            return try await assignLicensePlateEntity(
                licensePlate,
                vehicleId: vehicleId,
                validFrom: request.validFrom
            )
        }
    }

    func assignLicensePlate(
        licensePlateId: UUID,
        vehicleId: UUID,
        validFrom: Date? = nil
    ) async throws -> VehicleLicensePlateAssignment {
        try await Atlas.transaction {
            let licensePlate = try await requireEntity(
                id: licensePlateId,
                type: .licensePlate,
                label: "License plate"
            )

            return try await assignLicensePlateEntity(
                licensePlate,
                vehicleId: vehicleId,
                validFrom: validFrom
            )
        }
    }

    func unassignLicensePlate(
        licensePlateId: UUID,
        vehicleId: UUID,
        validUntil: Date = Date()
    ) async throws -> VehicleLicensePlateAssignment {
        try await Atlas.transaction {
            _ = try await requireEntity(
                id: vehicleId,
                type: .vehicle,
                label: "Vehicle"
            )
            let licensePlate = try await requireEntity(
                id: licensePlateId,
                type: .licensePlate,
                label: "License plate"
            )

            guard let relationship = try await Atlas.relationships(
                subject: licensePlateId,
                object: vehicleId,
                type: .licensePlateAssignment
            ).first else {
                throw Abort(
                    .notFound,
                    reason: "License plate isn't assigned to this vehicle"
                )
            }

            if let validFrom = relationship.validFrom, validUntil < validFrom {
                throw Abort(
                    .badRequest,
                    reason: "Assignment end cannot precede its start"
                )
            }

            return try await licensePlateAssignment(
                relationship: relationship.end(at: validUntil),
                licensePlate: licensePlate
            )
        }
    }

    func getLicensePlateHistory(
        vehicleId: UUID
    ) async throws -> [VehicleLicensePlateAssignment] {
        _ = try await requireEntity(
            id: vehicleId,
            type: .vehicle,
            label: "Vehicle"
        )

        let relationships = try await Atlas.relationships(
            object: vehicleId,
            type: .licensePlateAssignment,
            includeEnded: true
        )
        var assignments: [VehicleLicensePlateAssignment] = []

        for relationship in relationships {
            let licensePlate = try await requireEntity(
                id: relationship.subject,
                type: .licensePlate,
                label: "License plate"
            )
            assignments.append(
                try await licensePlateAssignment(
                    relationship: relationship,
                    licensePlate: licensePlate
                )
            )
        }

        return assignments.sorted {
            ($0.validFrom ?? .distantPast) > ($1.validFrom ?? .distantPast)
        }
    }

    // MARK: - Persistence Translation

    private func applyVehicleRequest(
        on vehicle: Entity,
        request: VehicleRequest,
        normalizedValues: NormalizedVehicleValues
    ) async throws {
        try await vehicle.setAttribute(
            .vehicleType,
            to: normalizedValues.vehicleType
        )
        try await setOptionalAttribute(
            .modelYear,
            value: request.modelYear.map(String.init),
            valueType: "integer",
            on: vehicle
        )
        try await setOptionalAttribute(
            .trim,
            value: normalizedValues.trim,
            on: vehicle
        )
        try await setOptionalAttribute(
            .color,
            value: normalizedValues.color,
            on: vehicle
        )
        try await setOptionalAttribute(
            .vin,
            value: normalizedValues.vin,
            on: vehicle
        )
    }

    private func setOptionalAttribute(
        _ key: AttributeKey,
        value: String?,
        valueType: String = "string",
        on entity: Entity
    ) async throws {
        if let value {
            try await entity.setAttribute(key, to: value, valueType: valueType)
        } else {
            try await entity.removeAttribute(key)
        }
    }

    private func replaceRelationship(
        from entity: Entity,
        type: RelationshipType,
        targetId: UUID?
    ) async throws {
        let currentRelationships = try await Atlas.relationships(
            subject: entity.id,
            type: type
        )

        if currentRelationships.count == 1,
           currentRelationships[0].object == targetId {
            return
        }

        for relationship in currentRelationships {
            try await relationship.end()
        }

        guard let targetId else {
            return
        }

        let target = try await Atlas.entity(id: targetId)
        try await entity.relate(to: target, as: type)
    }

    private func createLicensePlate(
        request: LicensePlateRequest
    ) async throws -> Entity {
        let displayNumber = try requireNonempty(
            request.displayNumber,
            field: "License plate number"
        )
        let normalizedNumber = try normalizePlateNumber(displayNumber)
        let jurisdictionCode = try requireNonempty(
            request.jurisdictionCode,
            field: "Jurisdiction code"
        ).uppercased()
        let countryCode = try requireNonempty(
            request.countryCode,
            field: "Country code"
        ).uppercased()

        for plate in try await Atlas.entities(
            ofType: .licensePlate
        ) {
            let attributes = try await plate.attributes()
            if attributes[.normalizedNumber]
                == normalizedNumber,
               attributes[.jurisdictionCode]
                == jurisdictionCode,
               attributes[.countryCode]
                == countryCode {
                throw Abort(.conflict, reason: "License plate already exists")
            }
        }

        let licensePlate = try await Atlas.createEntity(
            .licensePlate,
            "\(displayNumber) (\(jurisdictionCode))"
        )
        try await licensePlate.setAttribute(
            .displayNumber,
            to: displayNumber
        )
        try await licensePlate.setAttribute(
            .normalizedNumber,
            to: normalizedNumber
        )
        try await licensePlate.setAttribute(
            .jurisdictionCode,
            to: jurisdictionCode
        )
        try await licensePlate.setAttribute(
            .countryCode,
            to: countryCode
        )

        return licensePlate
    }

    private func assignLicensePlateEntity(
        _ licensePlate: Entity,
        vehicleId: UUID,
        validFrom: Date?
    ) async throws -> VehicleLicensePlateAssignment {
        let vehicle = try await requireEntity(
            id: vehicleId,
            type: .vehicle,
            label: "Vehicle"
        )

        guard try await Atlas.relationships(
            subject: licensePlate.id,
            type: .licensePlateAssignment
        ).isEmpty else {
            throw Abort(
                .conflict,
                reason: "License plate already has a current assignment"
            )
        }

        let relationship = try await licensePlate.relate(
            to: vehicle,
            as: .licensePlateAssignment,
            validFrom: validFrom
        )

        return try await licensePlateAssignment(
            relationship: relationship,
            licensePlate: licensePlate
        )
    }

    // MARK: - Lookups and Validation

    private func getModelEntities(for makeId: UUID) async throws -> [Entity] {
        let relationships = try await Atlas.relationships(
            object: makeId,
            type: .modelMake
        )
        var models: [Entity] = []

        for relationship in relationships {
            let model = try await requireEntity(
                id: relationship.subject,
                type: .vehicleModel,
                label: "Vehicle model"
            )
            models.append(model)
        }

        return models
    }

    private func findEntity(
        type: EntityType,
        attribute: AttributeKey,
        value: String
    ) async throws -> Entity? {
        for entity in try await Atlas.entities(ofType: type) where
            try await entity.attribute(attribute) == value {
            return entity
        }

        return nil
    }

    private func requireEntity(
        id: UUID,
        type: EntityType,
        label: String
    ) async throws -> Entity {
        let entity: Entity

        do {
            entity = try await Atlas.entity(id: id)
        } catch AtlasError.entityNotFound {
            throw Abort(.notFound, reason: "\(label) with ID doesn't exist")
        }

        guard entity.type == type else {
            throw Abort(.notFound, reason: "\(label) with ID doesn't exist")
        }

        return entity
    }

    private func validateMakeAndModel(
        makeId: UUID?,
        modelId: UUID?
    ) async throws {
        if let makeId {
            _ = try await requireEntity(
                id: makeId,
                type: .vehicleMake,
                label: "Vehicle make"
            )
        }

        guard let modelId else {
            return
        }

        guard let makeId else {
            throw Abort(.badRequest, reason: "A vehicle model requires a make")
        }

        _ = try await requireEntity(
            id: modelId,
            type: .vehicleModel,
            label: "Vehicle model"
        )

        guard try await Atlas.relationships(
            subject: modelId,
            object: makeId,
            type: .modelMake
        ).isEmpty == false else {
            throw Abort(
                .badRequest,
                reason: "Vehicle model doesn't belong to the selected make"
            )
        }
    }

    private func validateUniqueVIN(
        _ vin: String?,
        excluding excludedId: UUID? = nil
    ) async throws {
        guard let vin else {
            return
        }

        if let existing = try await findEntity(
            type: .vehicle,
            attribute: .vin,
            value: vin
        ), existing.id != excludedId {
            throw Abort(.conflict, reason: "VIN already belongs to another vehicle")
        }
    }

    // MARK: - Entity Hydration

    private func hydrateVehicleMake(from entity: Entity) -> VehicleMake {
        VehicleMake(id: entity.id, displayName: entity.displayName)
    }

    private func hydrateVehicleModel(from entity: Entity) async throws -> VehicleModel {
        guard let relationship = try await Atlas.relationships(
            subject: entity.id,
            type: .modelMake
        ).first else {
            throw Abort(
                .internalServerError,
                reason: "Vehicle model is missing its make relationship"
            )
        }

        return VehicleModel(
            id: entity.id,
            makeId: relationship.object,
            displayName: entity.displayName
        )
    }

    private func hydrateVehicle(from entity: Entity) async throws -> Vehicle {
        let attributes = try await entity.attributes()
        let make = try await relatedEntity(
            from: entity.id,
            relationshipType: .vehicleMake
        )
        let model = try await relatedEntity(
            from: entity.id,
            relationshipType: .vehicleModel
        )
        let hydratedModel: VehicleModel? = if let model {
            try await hydrateVehicleModel(from: model)
        } else {
            nil
        }

        return Vehicle(
            id: entity.id,
            entityId: entity.id,
            displayName: entity.displayName,
            vehicleType: try requiredAttribute(
                .vehicleType,
                from: attributes,
                entityLabel: "Vehicle"
            ),
            modelYear: attributes[.modelYear].flatMap(Int.init),
            make: make.map { hydrateVehicleMake(from: $0) },
            model: hydratedModel,
            trim: attributes[.trim],
            color: attributes[.color],
            vin: attributes[.vin]
        )
    }

    private func hydrateLicensePlate(from entity: Entity) async throws -> LicensePlate {
        let attributes = try await entity.attributes()

        return LicensePlate(
            id: entity.id,
            entityId: entity.id,
            displayNumber: try requiredAttribute(
                .displayNumber,
                from: attributes,
                entityLabel: "License plate"
            ),
            normalizedNumber: try requiredAttribute(
                .normalizedNumber,
                from: attributes,
                entityLabel: "License plate"
            ),
            jurisdictionCode: try requiredAttribute(
                .jurisdictionCode,
                from: attributes,
                entityLabel: "License plate"
            ),
            countryCode: try requiredAttribute(
                .countryCode,
                from: attributes,
                entityLabel: "License plate"
            )
        )
    }

    private func licensePlateAssignment(
        relationship: Relationship,
        licensePlate: Entity
    ) async throws -> VehicleLicensePlateAssignment {
        VehicleLicensePlateAssignment(
            relationshipId: relationship.id,
            licensePlate: try await hydrateLicensePlate(from: licensePlate),
            validFrom: relationship.validFrom,
            validUntil: relationship.validUntil
        )
    }

    private func relatedEntity(
        from entityId: UUID,
        relationshipType: RelationshipType
    ) async throws -> Entity? {
        guard let relationship = try await Atlas.relationships(
            subject: entityId,
            type: relationshipType
        ).first else {
            return nil
        }

        return try await Atlas.entity(id: relationship.object)
    }

    private func requiredAttribute(
        _ key: AttributeKey,
        from attributes: [AttributeKey: String],
        entityLabel: String
    ) throws -> String {
        guard let value = attributes[key] else {
            throw Abort(
                .internalServerError,
                reason: "\(entityLabel) is missing required attribute \(key.rawValue)"
            )
        }

        return value
    }

    // MARK: - Input Normalization

    private struct NormalizedVehicleValues: Sendable {
        let displayName: String
        let vehicleType: String
        let trim: String?
        let color: String?
        let vin: String?
    }

    private func normalizedVehicleValues(
        from request: VehicleRequest
    ) throws -> NormalizedVehicleValues {
        NormalizedVehicleValues(
            displayName: try requireNonempty(
                request.displayName,
                field: "Display name"
            ),
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
            throw Abort(
                .badRequest,
                reason: "VIN must contain letters or numbers"
            )
        }

        return normalizedVIN
    }

    private func normalizePlateNumber(_ plateNumber: String) throws -> String {
        let normalizedNumber = plateNumber.uppercased().filter {
            $0.isLetter || $0.isNumber
        }

        guard !normalizedNumber.isEmpty else {
            throw Abort(
                .badRequest,
                reason: "License plate must contain letters or numbers"
            )
        }

        return normalizedNumber
    }
}
