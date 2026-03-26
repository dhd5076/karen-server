//
//  LocationLog.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/17/26.
//

import Fluent
import Vapor

final class Location: Model, @unchecked Sendable {

    static let schema = "locations"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "type")
    var type: String

    @Field(key: "latitude")
    var latitude: Double

    @Field(key: "longitude")
    var longitude: Double

    @Field(key: "recorded_at")
    var recordedAt: Date

    @Field(key: "metadata")
    var metadata: [String: String]
    
    init() { }
    
    init(
        id: UUID? = nil,
        type: String,
        latitude: Double,
        longitude: Double,
        recordedAt: Date,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.recordedAt = recordedAt
        self.metadata = metadata
    }
}
