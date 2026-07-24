//
//  LicensePlate.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Fluent
import Vapor

final class LicensePlate: Model, @unchecked Sendable {

    static let schema = "licensePlates"

    enum FieldKeys {
        static let entity: FieldKey = "entity_id"
        static let displayNumber: FieldKey = "display_number"
        static let normalizedNumber: FieldKey = "normalized_number"
        static let jurisdictionCode: FieldKey = "jurisdiction_code"
        static let countryCode: FieldKey = "country_code"
    }

    @ID(key: .id)
    var id: UUID?

    @Parent(key: FieldKeys.entity)
    var entity: Entity

    @Field(key: FieldKeys.displayNumber)
    var displayNumber: String

    @Field(key: FieldKeys.normalizedNumber)
    var normalizedNumber: String

    @Field(key: FieldKeys.jurisdictionCode)
    var jurisdictionCode: String

    @Field(key: FieldKeys.countryCode)
    var countryCode: String

    init() { }

    init(
        id: UUID? = nil,
        entityId: UUID,
        displayNumber: String,
        normalizedNumber: String,
        jurisdictionCode: String,
        countryCode: String
    ) {
        self.id = id
        self.$entity.id = entityId
        self.displayNumber = displayNumber
        self.normalizedNumber = normalizedNumber
        self.jurisdictionCode = jurisdictionCode
        self.countryCode = countryCode
    }
}
