//
//  PantryTransaction.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Fluent
import Vapor

enum PantryTransactionType: String, Codable {
    case add
    case consume
    case transfer
    case adjust
    case spoil
}

final class PantryTransaction: Model, @unchecked Sendable {
    
    static let schema = "pantry_transactions"
    
    //TODO: Implement FieldKeys everywhere else
    enum FieldKeys {
        static let type: FieldKey = "type"
        static let product: FieldKey = "product"
        static let batch: FieldKey = "batch"
        static let fromPantry: FieldKey = "from_pantry"
        static let toPantry: FieldKey = "to_pantry"
        static let quantity: FieldKey = "quantity"
        static let createdAt: FieldKey = "created_at"
        static let note: FieldKey = "note"
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Enum(key: FieldKeys.type)
    var type: PantryTransactionType
    
    @Parent(key: FieldKeys.product)
    var product: PantryProduct
    
    @OptionalParent(key: FieldKeys.batch)
    var batch: PantryBatch?
    
    @OptionalParent(key: FieldKeys.fromPantry)
    var fromPantry: Pantry?
    
    @OptionalParent(key: FieldKeys.toPantry)
    var toPantry: Pantry?
    
    @Field(key: FieldKeys.quantity)
    var quantity: Double
    
    @Field(key: FieldKeys.createdAt)
    var createdAt: Date
    
    @OptionalField(key: FieldKeys.note)
    var note: String?
    
    init() {}
    
    init(
        id: UUID? = nil,
        type: PantryTransactionType,
        product: UUID,
        batch: UUID? = nil,
        fromPantry: UUID? = nil,
        toPantry: UUID? = nil,
        quantity: Double,
        createdAt: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.type = type
        self.$product.id = product
        self.$batch.id = batch
        self.$fromPantry.id = fromPantry
        self.$toPantry.id = toPantry
        self.quantity = quantity
        self.createdAt = createdAt
        self.note = note
    }
    
    func update(from update: PantryTransaction) {
        self.type = update.type
        self.$product.id = update.$product.id
        self.$batch.id = update.$batch.id
        self.$fromPantry.id = update.$fromPantry.id
        self.$toPantry.id = update.$toPantry.id
        self.quantity = update.quantity
        self.createdAt = update.createdAt
        self.note = update.note
    }
}
