//
//  VehicleController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import KarenShared
import Vapor

struct VehicleController: RouteCollection {

    private let vehicleService = VehicleService()

    func boot(routes: any RoutesBuilder) throws {
        routes.post(use: createVehicle)
        routes.get(use: getAllVehicles)
        routes.get(.parameter("id"), use: getVehicle)
        routes.put(.parameter("id"), use: updateVehicle)

        routes.post("makes", use: createMake)
        routes.get("makes", use: getAllMakes)
        routes.post(
            "makes",
            .parameter("makeId"),
            "models",
            use: createModel
        )
        routes.get(
            "makes",
            .parameter("makeId"),
            "models",
            use: getModels
        )

        routes.post(
            .parameter("id"),
            "license-plates",
            use: createAndAssignLicensePlate
        )
        routes.get(
            .parameter("id"),
            "license-plates",
            use: getLicensePlateHistory
        )
        routes.post(
            .parameter("id"),
            "license-plates",
            .parameter("plateId"),
            "assign",
            use: assignLicensePlate
        )
        routes.post(
            .parameter("id"),
            "license-plates",
            .parameter("plateId"),
            "unassign",
            use: unassignLicensePlate
        )
    }

    private func createVehicle(req: Request) async throws -> VehicleResponse {
        let request = try req.content.decode(VehicleRequest.self)
        return try await vehicleService.createVehicle(request: request, on: req.db)
    }

    private func getAllVehicles(req: Request) async throws -> [VehicleResponse] {
        try await vehicleService.getAllVehicleResponses(on: req.db)
    }

    private func getVehicle(req: Request) async throws -> VehicleResponse {
        try await vehicleService.getVehicleResponseById(
            id: try requireUUID("id", from: req),
            on: req.db
        )
    }

    private func updateVehicle(req: Request) async throws -> VehicleResponse {
        let request = try req.content.decode(VehicleRequest.self)

        return try await vehicleService.updateVehicle(
            id: try requireUUID("id", from: req),
            request: request,
            on: req.db
        )
    }

    private func createMake(req: Request) async throws -> VehicleMakeResponse {
        let request = try req.content.decode(VehicleNameRequest.self)
        return try await vehicleService.createMake(
            displayName: request.displayName,
            on: req.db
        )
    }

    private func getAllMakes(req: Request) async throws -> [VehicleMakeResponse] {
        try await vehicleService.getAllMakes(on: req.db)
    }

    private func createModel(req: Request) async throws -> VehicleModelResponse {
        let request = try req.content.decode(VehicleNameRequest.self)

        return try await vehicleService.createModel(
            makeId: try requireUUID("makeId", from: req),
            displayName: request.displayName,
            on: req.db
        )
    }

    private func getModels(req: Request) async throws -> [VehicleModelResponse] {
        try await vehicleService.getModels(
            for: try requireUUID("makeId", from: req),
            on: req.db
        )
    }

    private func createAndAssignLicensePlate(
        req: Request
    ) async throws -> VehicleLicensePlateResponse {
        let request = try req.content.decode(LicensePlateRequest.self)

        return try await vehicleService.createAndAssignLicensePlate(
            vehicleId: try requireUUID("id", from: req),
            request: request,
            on: req.db
        )
    }

    private func getLicensePlateHistory(
        req: Request
    ) async throws -> [VehicleLicensePlateResponse] {
        try await vehicleService.getLicensePlateHistory(
            vehicleId: try requireUUID("id", from: req),
            on: req.db
        )
    }

    private func assignLicensePlate(
        req: Request
    ) async throws -> VehicleLicensePlateResponse {
        let request = try req.content.decode(LicensePlateRelationshipRequest.self)

        return try await vehicleService.assignLicensePlate(
            licensePlateId: try requireUUID("plateId", from: req),
            vehicleId: try requireUUID("id", from: req),
            validFrom: request.effectiveAt,
            on: req.db
        )
    }

    private func unassignLicensePlate(
        req: Request
    ) async throws -> VehicleLicensePlateResponse {
        let request = try req.content.decode(LicensePlateRelationshipRequest.self)

        return try await vehicleService.unassignLicensePlate(
            licensePlateId: try requireUUID("plateId", from: req),
            vehicleId: try requireUUID("id", from: req),
            validUntil: request.effectiveAt ?? Date(),
            on: req.db
        )
    }

    private func requireUUID(_ name: String, from req: Request) throws -> UUID {
        try req.parameters.require(name, as: UUID.self)
    }
}
