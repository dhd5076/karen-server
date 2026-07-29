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

    func createMake(displayName: String) async throws -> VehicleMakeResponse {
        let displayName = try requireNonempty(displayName, field: "Make name")
        let normalizedName = normalizeCatalogName(displayName)

        return try await Atlas.transaction {
            guard try await findEntity(
                type: VehicleEntitySchema.EntityType.make,
                attribute: VehicleEntitySchema.Attribute.normalizedName,
                value: normalizedName
            ) == nil else {
                throw Abort(.conflict, reason: "Vehicle make already exists")
            }

            let make = try await Atlas.createEntity(
                type: VehicleEntitySchema.EntityType.make,
                displayName: displayName
            )
            try await make.setAttribute(
                VehicleEntitySchema.Attribute.normalizedName,
                to: normalizedName
            )

            return makeResponse(make)
        }
    }

    func getAllMakes() async throws -> [VehicleMakeResponse] {
        try await Atlas.entities(ofType: VehicleEntitySchema.EntityType.make)
            .map(makeResponse)
            .sorted {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
    }

    // MARK: - Model

    func createModel(
        makeId: UUID,
        displayName: String
    ) async throws -> VehicleModelResponse {
        let displayName = try requireNonempty(displayName, field: "Model name")
        let normalizedName = normalizeCatalogName(displayName)

        return try await Atlas.transaction {
            let make = try await requireEntity(
                id: makeId,
                type: VehicleEntitySchema.EntityType.make,
                label: "Vehicle make"
            )

            let existingModels = try await getModelEntities(for: makeId)
            for model in existingModels where
                try await model.attribute(VehicleEntitySchema.Attribute.normalizedName)
                    == normalizedName {
                throw Abort(
                    .conflict,
                    reason: "Vehicle model already exists for this make"
                )
            }

            let model = try await Atlas.createEntity(
                type: VehicleEntitySchema.EntityType.model,
                displayName: displayName
            )
            try await model.setAttribute(
                VehicleEntitySchema.Attribute.normalizedName,
                to: normalizedName
            )
            try await model.relate(
                to: make,
                as: VehicleEntitySchema.Relationship.modelMake
            )

            return VehicleModelResponse(
                id: model.id,
                makeId: make.id,
                displayName: model.displayName
            )
        }
    }

    func getModels(for makeId: UUID) async throws -> [VehicleModelResponse] {
        _ = try await requireEntity(
            id: makeId,
            type: VehicleEntitySchema.EntityType.make,
            label: "Vehicle make"
        )

        return try await getModelEntities(for: makeId)
            .map {
                VehicleModelResponse(
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

    func createVehicle(request: VehicleRequest) async throws -> VehicleResponse {
        let values = try normalizedVehicleValues(from: request)

        return try await Atlas.transaction {
            try await validateMakeAndModel(
                makeId: request.makeId,
                modelId: request.modelId
            )
            try await validateUniqueVIN(values.vin)

            let vehicle = try await Atlas.createEntity(
                type: VehicleEntitySchema.EntityType.vehicle,
                displayName: values.displayName
            )

            try await saveVehicleAttributes(
                on: vehicle,
                request: request,
                normalizedValues: values
            )
            try await replaceRelationship(
                from: vehicle,
                type: VehicleEntitySchema.Relationship.vehicleMake,
                targetId: request.makeId
            )
            try await replaceRelationship(
                from: vehicle,
                type: VehicleEntitySchema.Relationship.vehicleModel,
                targetId: request.modelId
            )

            return try await vehicleResponse(vehicle)
        }
    }

    func getAllVehicleResponses() async throws -> [VehicleResponse] {
        var responses: [VehicleResponse] = []

        for vehicle in try await Atlas.entities(
            ofType: VehicleEntitySchema.EntityType.vehicle
        ) {
            responses.append(try await vehicleResponse(vehicle))
        }

        return responses.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    func getVehicleResponseById(id: UUID) async throws -> VehicleResponse {
        try await vehicleResponse(
            try await requireEntity(
                id: id,
                type: VehicleEntitySchema.EntityType.vehicle,
                label: "Vehicle"
            )
        )
    }

    func updateVehicle(
        id: UUID,
        request: VehicleRequest
    ) async throws -> VehicleResponse {
        let values = try normalizedVehicleValues(from: request)

        return try await Atlas.transaction {
            let vehicle = try await requireEntity(
                id: id,
                type: VehicleEntitySchema.EntityType.vehicle,
                label: "Vehicle"
            )

            try await validateMakeAndModel(
                makeId: request.makeId,
                modelId: request.modelId
            )
            try await validateUniqueVIN(values.vin, excluding: id)

            let updatedVehicle = try await vehicle.updateDisplayName(values.displayName)
            try await saveVehicleAttributes(
                on: updatedVehicle,
                request: request,
                normalizedValues: values
            )
            try await replaceRelationship(
                from: updatedVehicle,
                type: VehicleEntitySchema.Relationship.vehicleMake,
                targetId: request.makeId
            )
            try await replaceRelationship(
                from: updatedVehicle,
                type: VehicleEntitySchema.Relationship.vehicleModel,
                targetId: request.modelId
            )

            return try await vehicleResponse(updatedVehicle)
        }
    }

    // MARK: - License Plate

    func createAndAssignLicensePlate(
        vehicleId: UUID,
        request: LicensePlateRequest
    ) async throws -> VehicleLicensePlateResponse {
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
    ) async throws -> VehicleLicensePlateResponse {
        try await Atlas.transaction {
            let licensePlate = try await requireEntity(
                id: licensePlateId,
                type: VehicleEntitySchema.EntityType.licensePlate,
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
    ) async throws -> VehicleLicensePlateResponse {
        try await Atlas.transaction {
            _ = try await requireEntity(
                id: vehicleId,
                type: VehicleEntitySchema.EntityType.vehicle,
                label: "Vehicle"
            )
            let licensePlate = try await requireEntity(
                id: licensePlateId,
                type: VehicleEntitySchema.EntityType.licensePlate,
                label: "License plate"
            )

            guard let relationship = try await Atlas.relationships(
                subject: licensePlateId,
                object: vehicleId,
                type: VehicleEntitySchema.Relationship.licensePlateAssignment
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

            return try await licensePlateRelationshipResponse(
                relationship: relationship.end(at: validUntil),
                licensePlate: licensePlate
            )
        }
    }

    func getLicensePlateHistory(
        vehicleId: UUID
    ) async throws -> [VehicleLicensePlateResponse] {
        _ = try await requireEntity(
            id: vehicleId,
            type: VehicleEntitySchema.EntityType.vehicle,
            label: "Vehicle"
        )

        let relationships = try await Atlas.relationships(
            object: vehicleId,
            type: VehicleEntitySchema.Relationship.licensePlateAssignment,
            includeEnded: true
        )
        var responses: [VehicleLicensePlateResponse] = []

        for relationship in relationships {
            let licensePlate = try await requireEntity(
                id: relationship.subject,
                type: VehicleEntitySchema.EntityType.licensePlate,
                label: "License plate"
            )
            responses.append(
                try await licensePlateRelationshipResponse(
                    relationship: relationship,
                    licensePlate: licensePlate
                )
            )
        }

        return responses.sorted {
            ($0.validFrom ?? .distantPast) > ($1.validFrom ?? .distantPast)
        }
    }

    // MARK: - Persistence Translation

    private func saveVehicleAttributes(
        on vehicle: Entity,
        request: VehicleRequest,
        normalizedValues: NormalizedVehicleValues
    ) async throws {
        try await vehicle.setAttribute(
            VehicleEntitySchema.Attribute.vehicleType,
            to: normalizedValues.vehicleType
        )
        try await setOptionalAttribute(
            VehicleEntitySchema.Attribute.modelYear,
            value: request.modelYear.map(String.init),
            valueType: "integer",
            on: vehicle
        )
        try await setOptionalAttribute(
            VehicleEntitySchema.Attribute.trim,
            value: normalizedValues.trim,
            on: vehicle
        )
        try await setOptionalAttribute(
            VehicleEntitySchema.Attribute.color,
            value: normalizedValues.color,
            on: vehicle
        )
        try await setOptionalAttribute(
            VehicleEntitySchema.Attribute.vin,
            value: normalizedValues.vin,
            on: vehicle
        )
    }

    private func setOptionalAttribute(
        _ name: String,
        value: String?,
        valueType: String = "string",
        on entity: Entity
    ) async throws {
        if let value {
            try await entity.setAttribute(name, to: value, valueType: valueType)
        } else {
            try await entity.removeAttribute(name)
        }
    }

    private func replaceRelationship(
        from entity: Entity,
        type: String,
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
            ofType: VehicleEntitySchema.EntityType.licensePlate
        ) {
            let attributes = try await plate.attributes()
            if attributes[VehicleEntitySchema.Attribute.normalizedNumber]
                == normalizedNumber,
               attributes[VehicleEntitySchema.Attribute.jurisdictionCode]
                == jurisdictionCode,
               attributes[VehicleEntitySchema.Attribute.countryCode]
                == countryCode {
                throw Abort(.conflict, reason: "License plate already exists")
            }
        }

        let licensePlate = try await Atlas.createEntity(
            type: VehicleEntitySchema.EntityType.licensePlate,
            displayName: "\(displayNumber) (\(jurisdictionCode))"
        )
        try await licensePlate.setAttribute(
            VehicleEntitySchema.Attribute.displayNumber,
            to: displayNumber
        )
        try await licensePlate.setAttribute(
            VehicleEntitySchema.Attribute.normalizedNumber,
            to: normalizedNumber
        )
        try await licensePlate.setAttribute(
            VehicleEntitySchema.Attribute.jurisdictionCode,
            to: jurisdictionCode
        )
        try await licensePlate.setAttribute(
            VehicleEntitySchema.Attribute.countryCode,
            to: countryCode
        )

        return licensePlate
    }

    private func assignLicensePlateEntity(
        _ licensePlate: Entity,
        vehicleId: UUID,
        validFrom: Date?
    ) async throws -> VehicleLicensePlateResponse {
        let vehicle = try await requireEntity(
            id: vehicleId,
            type: VehicleEntitySchema.EntityType.vehicle,
            label: "Vehicle"
        )

        guard try await Atlas.relationships(
            subject: licensePlate.id,
            type: VehicleEntitySchema.Relationship.licensePlateAssignment
        ).isEmpty else {
            throw Abort(
                .conflict,
                reason: "License plate already has a current assignment"
            )
        }

        let relationship = try await licensePlate.relate(
            to: vehicle,
            as: VehicleEntitySchema.Relationship.licensePlateAssignment,
            validFrom: validFrom
        )

        return try await licensePlateRelationshipResponse(
            relationship: relationship,
            licensePlate: licensePlate
        )
    }

    // MARK: - Lookups and Validation

    private func getModelEntities(for makeId: UUID) async throws -> [Entity] {
        let relationships = try await Atlas.relationships(
            object: makeId,
            type: VehicleEntitySchema.Relationship.modelMake
        )
        var models: [Entity] = []

        for relationship in relationships {
            let model = try await requireEntity(
                id: relationship.subject,
                type: VehicleEntitySchema.EntityType.model,
                label: "Vehicle model"
            )
            models.append(model)
        }

        return models
    }

    private func findEntity(
        type: String,
        attribute: String,
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
        type: String,
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
                type: VehicleEntitySchema.EntityType.make,
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
            type: VehicleEntitySchema.EntityType.model,
            label: "Vehicle model"
        )

        guard try await Atlas.relationships(
            subject: modelId,
            object: makeId,
            type: VehicleEntitySchema.Relationship.modelMake
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
            type: VehicleEntitySchema.EntityType.vehicle,
            attribute: VehicleEntitySchema.Attribute.vin,
            value: vin
        ), existing.id != excludedId {
            throw Abort(.conflict, reason: "VIN already belongs to another vehicle")
        }
    }

    // MARK: - Responses

    private func makeResponse(_ make: Entity) -> VehicleMakeResponse {
        VehicleMakeResponse(id: make.id, displayName: make.displayName)
    }

    private func modelResponse(_ model: Entity) async throws -> VehicleModelResponse {
        guard let relationship = try await Atlas.relationships(
            subject: model.id,
            type: VehicleEntitySchema.Relationship.modelMake
        ).first else {
            throw Abort(
                .internalServerError,
                reason: "Vehicle model is missing its make relationship"
            )
        }

        return VehicleModelResponse(
            id: model.id,
            makeId: relationship.object,
            displayName: model.displayName
        )
    }

    private func vehicleResponse(_ vehicle: Entity) async throws -> VehicleResponse {
        let attributes = try await vehicle.attributes()
        let make = try await relatedEntity(
            from: vehicle.id,
            relationshipType: VehicleEntitySchema.Relationship.vehicleMake
        )
        let model = try await relatedEntity(
            from: vehicle.id,
            relationshipType: VehicleEntitySchema.Relationship.vehicleModel
        )
        let modelResponse: VehicleModelResponse? = if let model {
            try await modelResponse(model)
        } else {
            nil
        }

        return VehicleResponse(
            id: vehicle.id,
            entityId: vehicle.id,
            displayName: vehicle.displayName,
            vehicleType: try requiredAttribute(
                VehicleEntitySchema.Attribute.vehicleType,
                from: attributes,
                entityLabel: "Vehicle"
            ),
            modelYear: attributes[VehicleEntitySchema.Attribute.modelYear].flatMap(Int.init),
            make: make.map(makeResponse),
            model: modelResponse,
            trim: attributes[VehicleEntitySchema.Attribute.trim],
            color: attributes[VehicleEntitySchema.Attribute.color],
            vin: attributes[VehicleEntitySchema.Attribute.vin]
        )
    }

    private func licensePlateResponse(
        _ licensePlate: Entity
    ) async throws -> LicensePlateResponse {
        let attributes = try await licensePlate.attributes()

        return LicensePlateResponse(
            id: licensePlate.id,
            entityId: licensePlate.id,
            displayNumber: try requiredAttribute(
                VehicleEntitySchema.Attribute.displayNumber,
                from: attributes,
                entityLabel: "License plate"
            ),
            normalizedNumber: try requiredAttribute(
                VehicleEntitySchema.Attribute.normalizedNumber,
                from: attributes,
                entityLabel: "License plate"
            ),
            jurisdictionCode: try requiredAttribute(
                VehicleEntitySchema.Attribute.jurisdictionCode,
                from: attributes,
                entityLabel: "License plate"
            ),
            countryCode: try requiredAttribute(
                VehicleEntitySchema.Attribute.countryCode,
                from: attributes,
                entityLabel: "License plate"
            )
        )
    }

    private func licensePlateRelationshipResponse(
        relationship: Relationship,
        licensePlate: Entity
    ) async throws -> VehicleLicensePlateResponse {
        VehicleLicensePlateResponse(
            relationshipId: relationship.id,
            licensePlate: try await licensePlateResponse(licensePlate),
            validFrom: relationship.validFrom,
            validUntil: relationship.validUntil
        )
    }

    private func relatedEntity(
        from entityId: UUID,
        relationshipType: String
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
        _ name: String,
        from attributes: [String: String],
        entityLabel: String
    ) throws -> String {
        guard let value = attributes[name] else {
            throw Abort(
                .internalServerError,
                reason: "\(entityLabel) is missing required attribute \(name)"
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
