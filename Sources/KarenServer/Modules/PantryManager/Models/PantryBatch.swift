//
//  PantryBatch.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Fluent
import Vapor

final class PantryBatch: Model, @unchecked Sendable {
    
    static let schema = "pantry_batch"
    
    enum FieldKeys {
        static let name: FieldKey = "name"
        static let product: FieldKey = "product"
        static let quantity: FieldKey = "quantity"
        static let source: FieldKey = "source"
        static let aquiredAt: FieldKey = "aquired_at"
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: FieldKeys.product)
    var product: PantryProduct
    
    @Field(key: FieldKeys.quantity)
    var quantity: Double
    
    //TODO: Make Source into a model??
    @Field(key: FieldKeys.source)
    var source: String
    
    @Field(key: FieldKeys.aquiredAt)
    var aquiredAt: Date
    
    init() { }
    
    init(
        id: UUID? = nil
    ) {
        self.id = id
    }
}
