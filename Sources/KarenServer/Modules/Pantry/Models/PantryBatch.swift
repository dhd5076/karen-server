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
        static let pantry: FieldKey = "pantry"
        static let product: FieldKey = "product"
        static let quantity: FieldKey = "quantity"
        static let source: FieldKey = "source"
        static let acquiredAt: FieldKey = "acquired_at"
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: FieldKeys.pantry)
    var pantry: Pantry
    
    @Parent(key: FieldKeys.product)
    var product: PantryProduct
    
    @Field(key: FieldKeys.quantity)
    var quantity: Double
    
    //TODO: Make Source into a model??
    @Field(key: FieldKeys.source)
    var source: String
    
    @Field(key: FieldKeys.acquiredAt)
    var acquiredAt: Date
    
    init() { }
    
    init(
        id: UUID? = nil,
        pantry: UUID,
        product: UUID,
        quantity: Double,
        source: String,
        acquiredAt: Date
    ) {
        self.id = id
        self.$pantry.id = pantry
        self.$product.id = product
        self.quantity = quantity
        self.source = source
        self.acquiredAt = acquiredAt
    }
    
    func update(from update: PantryBatch) {
        self.$pantry.id = update.$pantry.id
        self.$product.id = update.$product.id
        self.quantity = update.quantity
        self.source = update.source
        self.acquiredAt = update.acquiredAt
    }
}
