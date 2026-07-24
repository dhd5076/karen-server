//
//  VehicleModel.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Fluent
import Vapor

final class VehicleModel: Model, @unchecked Sendable {

    static let schema = "vehicleModels"

    enum FieldKeys {
        static let make: FieldKey = "make_id"
        static let displayName: FieldKey = "display_name"
        static let normalizedName: FieldKey = "normalized_name"
    }

    @ID(key: .id)
    var id: UUID?

    @Parent(key: FieldKeys.make)
    var make: VehicleMake

    @Field(key: FieldKeys.displayName)
    var displayName: String

    @Field(key: FieldKeys.normalizedName)
    var normalizedName: String

    init() { }

    init(
        id: UUID? = nil,
        makeId: UUID,
        displayName: String,
        normalizedName: String
    ) {
        self.id = id
        self.$make.id = makeId
        self.displayName = displayName
        self.normalizedName = normalizedName
    }
}
