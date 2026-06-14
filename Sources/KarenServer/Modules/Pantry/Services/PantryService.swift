//
//  PantryService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Foundation
import Fluent
import Vapor
import KarenShared


struct PantryService {
    
    //TODO: Implement update
    //TODO: Implement delete, get, update in controllers
    
    // MARK: - Pantry
    
    func createPantry(pantry: Pantry, on db: any Database) async throws -> Pantry {
        try await pantry.save(on:db)
        
        return pantry
    }
    
    func getAllPantry(on db: any Database) async throws -> [Pantry] {
        return try await Pantry.query(on: db).all()
    }
    
    func getPantryById(id: UUID, on db: any Database) async throws -> Pantry {
        guard let pantry = try await Pantry.find(id, on: db) else {
            throw Abort(.notFound, reason: "Pantry with ID doesn't exist")
        }
        
        return pantry
    }
    
    func updatePantry(pantry: Pantry, on db: any Database) async throws -> Pantry {
        let existingPantry = try await getPantryById(id: try pantry.requireID(), on: db)
        
        existingPantry.update(from: pantry)
        
        try await existingPantry.update(on: db)
        
        return existingPantry
    }
    
    func deletePantry(id: UUID, on db: any Database) async throws {
        let pantry = try await getPantryById(id: id, on: db)
        
        try await pantry.delete(on: db)
    }
    
    // MARK: - Batch
    
    func createPantryBatch(pantryBatch: PantryBatch, on db: any Database) async throws -> PantryBatch {
        try await pantryBatch.save(on: db)
        
        return pantryBatch
    }
    
    func getAllPantryBatch(on db: any Database) async throws -> [PantryBatch] {
        return try await PantryBatch.query(on: db).all()
    }
    
    func getPantryBatchById(id: UUID, on db: any Database) async throws -> PantryBatch {
        guard let pantryBatch = try await PantryBatch.find(id, on: db) else {
            throw Abort(.notFound, reason: "PantryBatch with ID doesn't exist")
        }
        
        return pantryBatch
    }
    
    func updatePantryBatch(pantryBatch: PantryBatch, on db: any Database) async throws -> PantryBatch {
        let existingPantryBatch = try await getPantryBatchById(id: try pantryBatch.requireID(), on: db)
        
        existingPantryBatch.update(from: pantryBatch) //TODO: naming collision, should maybe rename .update, works now due to signature
        
        try await existingPantryBatch.update(on: db)
        
        return existingPantryBatch
    }
    
    func deletePantryBatch(id: UUID, on db: any Database) async throws {
        let pantryBatch = try await getPantryBatchById(id: id, on: db)
        
        let transactions = try await PantryTransaction.query(on: db) //TODO: This is a little bit janky, need a better way to handle delete
                .filter(\.$batch.$id == id)
                .all()

        try await transactions.delete(on: db)
        try await pantryBatch.delete(on: db)
    }

    func consumePantryBatch(
        batchId: UUID,
        request: KarenShared.ConsumePantryBatchRequest,
        on db: any Database
    ) async throws -> PantryBatch {
        guard request.quantity > 0 else {
            throw Abort(.badRequest, reason: "Quantity must be greater than zero")
        }

        let batch = try await getPantryBatchById(id: batchId, on: db)

        guard request.quantity <= batch.quantity else {
            throw Abort(.badRequest, reason: "Cannot consume more than the batch quantity")
        }

        batch.quantity -= request.quantity

        if batch.quantity < 0.000001 {
            batch.quantity = 0
        }

        try await batch.update(on: db)

        let transaction = PantryTransaction(
            type: .consume,
            product: batch.$product.id,
            batch: try batch.requireID(),
            fromPantry: batch.$pantry.id,
            quantity: request.quantity,
            note: request.note
        )

        _ = try await createPantryTransaction(pantryTransaction: transaction, on: db)

        return batch
    }
    
    // MARK: - Product
    
    func createPantryProduct(pantryProduct: PantryProduct, on db: any Database) async throws -> PantryProduct {
        try await pantryProduct.save(on: db)
        
        return pantryProduct
    }
    
    func getAllPantryProduct(on db: any Database) async throws -> [PantryProduct] {
        return try await PantryProduct.query(on: db).all()
    }
    
    func getPantryProductById(id: UUID, on db: any Database) async throws -> PantryProduct {
        guard let pantryProduct = try await PantryProduct.find(id, on: db) else {
            throw Abort(.notFound, reason: "PantryProduct with ID doesn't exist")
        }
        
        return pantryProduct
            
    }
    
    func updatePantryProduct(pantryProduct: PantryProduct, on db: any Database) async throws -> PantryProduct {
        let existingPantryProduct = try await getPantryProductById(id: try pantryProduct.requireID(), on: db)
        
        existingPantryProduct.update(from: pantryProduct)
        
        try await existingPantryProduct.update(on: db)
        
        return existingPantryProduct
    }
    
    func deletePantryProduct(id: UUID, on db: any Database) async throws {
        let pantryProduct = try await getPantryProductById(id: id, on: db)
        
        try await pantryProduct.delete(on: db)
    }
    
    // MARK: - Transaction
    
    func createPantryTransaction(pantryTransaction: PantryTransaction, on db: any Database) async throws -> PantryTransaction {
        try await pantryTransaction.save(on: db)
        
        return pantryTransaction
    }
    
    func getAllPantryTransaction(on db: any Database) async throws -> [PantryTransaction] {
        return try await PantryTransaction.query(on: db).all()
    }
    
    func getPantryTransactionById(id: UUID, on db: any Database) async throws -> PantryTransaction {
        guard let pantryTransaction = try await PantryTransaction.find(id, on: db) else {
            throw Abort(.notFound, reason: "PantryTransaction with ID doesn't exist")
        }
        
        return pantryTransaction
    }
    
    func updatePantryTransaction(pantryTransaction: PantryTransaction, on db: any Database) async throws -> PantryTransaction  {
        let existingPantryTransaction = try await getPantryTransactionById(id: pantryTransaction.requireID(), on: db)
        
        existingPantryTransaction.update(from: pantryTransaction)
        
        try await existingPantryTransaction.update(on: db)
        
        return existingPantryTransaction
    }
    
    func deletePantryTransaction(id: UUID, on db: any Database) async throws {
        let pantryTransaction = try await getPantryTransactionById(id: id, on: db)
        
        try await pantryTransaction.delete(on: db)
    }
    
    //Misc. Functions
    
    func addBatchToPantry(pantryId: UUID, request: KarenShared.AddBatchToPantryRequest, on db: any Database) async throws -> PantryBatch {
        guard request.quantity > 0 else {
            throw Abort(.badRequest, reason: "Quantity must be greater than zero")
        }
        
        let pantryBatch = PantryBatch(
            pantry: pantryId,
            product: request.product,
            quantity: request.quantity,
            source: request.source,
            acquiredAt: request.acquiredAt ?? Date()
        ) //TODO: Verify pantry and product exist??
        
        let createdBatch = try await createPantryBatch(pantryBatch: pantryBatch, on: db)
        
        let transaction = PantryTransaction(
            type: .add,
            product: request.product,
            batch: try createdBatch.requireID(),
            toPantry: pantryId,
            quantity: request.quantity,
            note: request.note
        )
        
        _ = try await createPantryTransaction(pantryTransaction: transaction, on: db)
        
        return createdBatch
    }
    
    func getPantryBatches(pantryId: UUID, on db: any Database) async throws -> [PantryBatch] {
        _ = try await getPantryById(id: pantryId, on: db)
        
        return try await PantryBatch.query(on: db)
            .filter(\.$pantry.$id == pantryId)
            .filter(\.$quantity > 0)
            .all()
    }
}
