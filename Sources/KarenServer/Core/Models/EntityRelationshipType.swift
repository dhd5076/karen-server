//
//  EntityRelationshipType.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import Fluent
import Vapor

final class EntityRelationshipType: Model, @unchecked Sendable {
    
    static let schema = "entityRelationshipTypes"
    
    enum FieldKeys {
        static let displayName: FieldKey = "display_name"
        static let inverseDisplayName: FieldKey = "inverse_display_name"
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: FieldKeys.displayName)
    var displayName: String
    
    @Field(key: FieldKeys.inverseDisplayName)
    var inverseDisplayName: String
    
    init () { }
    
    init(
        id: UUID? = nil,
        displayName: String,
        inverseDisplayName: String
    ) {
        self.id = id
        self.displayName = displayName
        self.inverseDisplayName = inverseDisplayName
    }
}
