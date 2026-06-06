//
//  CreatePantryRequest.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

enum PantryDTO {
    
    
    struct Pantry: Content {
        let id: UUID?
        let name: String
        
        init(model: KarenServer.Pantry) throws {
            self.id = try model.requireID()
            self.name = model.name
        }
        
        func toModel() -> KarenServer.Pantry {
            KarenServer.Pantry(
                id: self.id,
                name: self.name
            )
        }
    }
    
    
    struct PantryBatch: Content {
        let id: UUID?
        let pantry: UUID
        let product: UUID
        let quantity: Double
        let source: String
        let acquiredAt: Date
        
        init(model: KarenServer.PantryBatch) throws {
            self.id = try model.requireID()
            self.pantry = model.$pantry.id
            self.product = model.$product.id
            self.quantity = model.quantity
            self.source = model.source
            self.acquiredAt = model.acquiredAt
        }
        
        func toModel() -> KarenServer.PantryBatch {
            KarenServer.PantryBatch(
                id: self.id,
                pantry: self.pantry,
                product: self.product,
                quantity: self.quantity,
                source: self.source,
                acquiredAt: self.acquiredAt
            )
        }
    }
    
    struct PantryProduct: Content {
        let id: UUID?
        let name: String
        let unit: String
        let proteinPerUnit: Double
        let carbsPerUnit: Double
        let fatPerUnit: Double
        let shelfLife: Int
        
        init(model: KarenServer.PantryProduct) throws {
            self.id = try model.requireID()
            self.name = model.name
            self.unit = model.unit
            self.proteinPerUnit = model.proteinPerUnit
            self.carbsPerUnit = model.carbsPerUnit
            self.fatPerUnit = model.fatPerUnit
            self.shelfLife = model.shelfLife
        }
        
        func toModel() -> KarenServer.PantryProduct {
            KarenServer.PantryProduct(
                id: self.id,
                name: self.name,
                unit: self.unit,
                proteinPerUnit: self.proteinPerUnit,
                carbsPerUnit: self.carbsPerUnit,
                fatPerUnit: self.fatPerUnit,
                shelfLife: self.shelfLife
            )
            
        }
    }
    
    struct PantryTransaction: Content {
        let id: UUID?
        let type: PantryTransactionType
        let product: UUID
        let batch: UUID?
        let fromPantry: UUID?
        let toPantry: UUID?
        let quantity: Double
        let note: String?
        
        init(model: KarenServer.PantryTransaction) throws {
            self.id = try model.requireID()
            self.type = model.type
            self.product = model.$product.id
            self.batch = model.$batch.id
            self.fromPantry = model.$fromPantry.id
            self.toPantry = model.$toPantry.id
            self.quantity = model.quantity
            self.note = model.note
        }
        
        func toModel() -> KarenServer.PantryTransaction {
            KarenServer.PantryTransaction(
                id: self.id,
                type: self.type,
                product: self.product,
                batch: self.batch,
                fromPantry: self.fromPantry,
                toPantry: self.toPantry,
                quantity: self.quantity,
                note: self.note
            )
        }
    }
}
