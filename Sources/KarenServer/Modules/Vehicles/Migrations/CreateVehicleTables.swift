//
//  CreateVehicleTables.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Fluent

struct CreateVehicleTables: AsyncMigration {

    func prepare(on database: any Database) async throws {
        try await database.schema(VehicleMake.schema)
            .id()
            .field(VehicleMake.FieldKeys.displayName, .string, .required)
            .field(VehicleMake.FieldKeys.normalizedName, .string, .required)
            .unique(on: VehicleMake.FieldKeys.normalizedName)
            .create()

        try await database.schema(VehicleModel.schema)
            .id()
            .field(
                VehicleModel.FieldKeys.make,
                .uuid,
                .required,
                .references(VehicleMake.schema, "id", onDelete: .restrict)
            )
            .field(VehicleModel.FieldKeys.displayName, .string, .required)
            .field(VehicleModel.FieldKeys.normalizedName, .string, .required)
            .unique(
                on: VehicleModel.FieldKeys.make,
                VehicleModel.FieldKeys.normalizedName
            )
            .create()

        try await database.schema(Vehicle.schema)
            .id()
            .field(
                Vehicle.FieldKeys.entity,
                .uuid,
                .required,
                .references(Entity.schema, "id", onDelete: .restrict)
            )
            .field(Vehicle.FieldKeys.vehicleType, .string, .required)
            .field(Vehicle.FieldKeys.modelYear, .int)
            .field(
                Vehicle.FieldKeys.make,
                .uuid,
                .references(VehicleMake.schema, "id", onDelete: .restrict)
            )
            .field(
                Vehicle.FieldKeys.model,
                .uuid,
                .references(VehicleModel.schema, "id", onDelete: .restrict)
            )
            .field(Vehicle.FieldKeys.trim, .string)
            .field(Vehicle.FieldKeys.color, .string)
            .field(Vehicle.FieldKeys.vin, .string)
            .unique(on: Vehicle.FieldKeys.entity)
            .unique(on: Vehicle.FieldKeys.vin)
            .create()

        try await database.schema(LicensePlate.schema)
            .id()
            .field(
                LicensePlate.FieldKeys.entity,
                .uuid,
                .required,
                .references(Entity.schema, "id", onDelete: .restrict)
            )
            .field(LicensePlate.FieldKeys.displayNumber, .string, .required)
            .field(LicensePlate.FieldKeys.normalizedNumber, .string, .required)
            .field(LicensePlate.FieldKeys.jurisdictionCode, .string, .required)
            .field(LicensePlate.FieldKeys.countryCode, .string, .required)
            .unique(on: LicensePlate.FieldKeys.entity)
            .unique(
                on: LicensePlate.FieldKeys.normalizedNumber,
                LicensePlate.FieldKeys.jurisdictionCode,
                LicensePlate.FieldKeys.countryCode
            )
            .create()

    }

    func revert(on database: any Database) async throws {
        try await database.schema(LicensePlate.schema).delete()
        try await database.schema(Vehicle.schema).delete()
        try await database.schema(VehicleModel.schema).delete()
        try await database.schema(VehicleMake.schema).delete()
    }
}
