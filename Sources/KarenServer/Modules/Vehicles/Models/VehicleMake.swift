//
//  VehicleMake.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Fluent
import Vapor

final class VehicleMake: Model, @unchecked Sendable {

    static let schema = "vehicleMakes"

    enum FieldKeys {
        static let displayName: FieldKey = "display_name"
        static let normalizedName: FieldKey = "normalized_name"
    }

    @ID(key: .id)
    var id: UUID?

    @Field(key: FieldKeys.displayName)
    var displayName: String

    @Field(key: FieldKeys.normalizedName)
    var normalizedName: String

    init() { }

    init(
        id: UUID? = nil,
        displayName: String,
        normalizedName: String
    ) {
        self.id = id
        self.displayName = displayName
        self.normalizedName = normalizedName
    }
}
