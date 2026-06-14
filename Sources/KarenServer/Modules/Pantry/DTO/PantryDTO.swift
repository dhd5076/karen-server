//
//  CreatePantryRequest.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor
import KarenShared

extension KarenShared.Pantry: @retroactive Content {}

extension KarenShared.Pantry {
    init(model: KarenServer.Pantry) throws {
        self.init(
            id: try model.requireID(),
            name: model.name
        )
    }
    
    func toModel() -> KarenServer.Pantry {
        KarenServer.Pantry(
            id: self.id,
            name: self.name
        )
    }
}

extension KarenShared.PantryBatch: @retroactive Content {}

extension KarenShared.PantryBatch {
    init(model: KarenServer.PantryBatch) throws {
        self.init(
            id: try model.requireID(),
            pantry: model.$pantry.id,
            product: model.$product.id,
            quantity: model.quantity,
            source: model.source,
            acquiredAt: model.acquiredAt,
        )
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

extension KarenShared.PantryProduct: @retroactive Content {}

extension KarenShared.PantryProduct {
    init(model: KarenServer.PantryProduct) throws {
        self.init(
            id: try model.requireID(),
            name: model.name,
            unit: model.unit,
            proteinPerUnit: model.proteinPerUnit,
            carbsPerUnit: model.carbsPerUnit,
            fatPerUnit: model.fatPerUnit,
            shelfLife : model.shelfLife
        )
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

extension KarenShared.PantryTransaction.DTO: @retroactive Content {}

extension KarenShared.PantryTransaction.DTO {
    init(model: KarenServer.PantryTransaction) throws {
        self.init(
            id: try model.requireID(),
            type: model.type,
            product: model.$product.id,
            batch: model.$batch.id,
            fromPantry: model.$fromPantry.id,
            toPantry: model.$toPantry.id,
            quantity: model.quantity,
            note: model.note
        )
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

extension AddBatchToPantryRequest: @retroactive Content {}

