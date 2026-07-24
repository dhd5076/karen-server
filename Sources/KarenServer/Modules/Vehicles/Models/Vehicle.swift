//
//  Vehicle.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Fluent
import Vapor

final class Vehicle: Model, @unchecked Sendable {

    static let schema = "vehicles"

    enum FieldKeys {
        static let entity: FieldKey = "entity_id"
        static let vehicleType: FieldKey = "vehicle_type"
        static let modelYear: FieldKey = "model_year"
        static let make: FieldKey = "make_id"
        static let model: FieldKey = "model_id"
        static let trim: FieldKey = "trim"
        static let color: FieldKey = "color"
        static let vin: FieldKey = "vin"
    }

    @ID(key: .id)
    var id: UUID?

    @Parent(key: FieldKeys.entity)
    var entity: Entity

    @Field(key: FieldKeys.vehicleType)
    var vehicleType: String

    @OptionalField(key: FieldKeys.modelYear)
    var modelYear: Int?

    @OptionalParent(key: FieldKeys.make)
    var make: VehicleMake?

    @OptionalParent(key: FieldKeys.model)
    var model: VehicleModel?

    @OptionalField(key: FieldKeys.trim)
    var trim: String?

    @OptionalField(key: FieldKeys.color)
    var color: String?

    @OptionalField(key: FieldKeys.vin)
    var vin: String?

    init() { }

    init(
        id: UUID? = nil,
        entityId: UUID,
        vehicleType: String,
        modelYear: Int? = nil,
        makeId: UUID? = nil,
        modelId: UUID? = nil,
        trim: String? = nil,
        color: String? = nil,
        vin: String? = nil
    ) {
        self.id = id
        self.$entity.id = entityId
        self.vehicleType = vehicleType
        self.modelYear = modelYear
        self.$make.id = makeId
        self.$model.id = modelId
        self.trim = trim
        self.color = color
        self.vin = vin
    }
}
