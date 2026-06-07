//
//  Pantry.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Fluent
import Vapor

final class Pantry: Model, @unchecked Sendable {
    
    static let schema = "pantry"
    
    enum FieldKeys {
        static let name: FieldKey = "name"
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: FieldKeys.name)
    var name: String
    
    init () { }
    
    init(
        id: UUID? = nil,
        name: String
    ) {
        self.id = id
        self.name = name
    }
    
    func update(from update: Pantry) {
        self.name = update.name
    }
}
