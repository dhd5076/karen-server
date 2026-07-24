//
//  Entity.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Fluent
import Vapor

final class Entity: Model, @unchecked Sendable {
    
    static let schema = "entity"
    
    enum FieldKeys {
        static let entityType: FieldKey = "entity_type"
        static let displayName: FieldKey = "display_name"
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: FieldKeys.entityType)
    var entityType: String
    
    @Field(key: FieldKeys.displayName)
    var displayName: String
    
    func update(from update: Entity) {
        self.entityType = update.entityType
        self.displayName = update.displayName
    }
}
