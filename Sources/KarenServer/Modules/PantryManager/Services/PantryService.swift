//
//  PantryService.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Foundation
import Fluent
import Vapor

struct PantryService {
    
    //TODO: Implement get, update, delete etc
    
    // MARK: - Pantry
    
    func createPantry(pantry: Pantry, on db: any Database) async throws -> Pantry {
        try await pantry.save(on:db)
        
        return pantry
    }
    
    func deletePantry(id: UUID, on db: any Database) async throws {
        guard let pantry = try await Pantry.query(on: db)
            .filter(\.$id == id).first() else {
            throw Abort(.notFound, reason: "Pantry with ID doesn't exist")
        }
        
        try await pantry.delete(on: db)
    }
    
    // MARK: - Batch
    
    func createPantryBatch(pantryBatch: PantryBatch, on db: any Database) async throws -> PantryBatch {
        try await pantryBatch.save(on: db)
        
        return pantryBatch
    }
    
    func deletePantryBatch(id: UUID, on db: any Database) async throws {
        guard let pantryBatch = try await PantryBatch.query(on: db)
            .filter(\.$id == id).first() else {
            throw Abort(.notFound, reason: "PantryBatch with ID doesn't exist")
        }
        
        try await pantryBatch.delete(on: db)
    }
    
    // MARK: - Product
    
    func createPantryProduct(pantryProduct: PantryProduct, on db: any Database) async throws -> PantryProduct {
        try await pantryProduct.save(on: db)
        
        return pantryProduct
    }
    
    func deletePantryProduct(id: UUID, on db: any Database) async throws {
        guard let pantryProduct = try await PantryProduct.query(on: db)
            .filter(\.$id == id).first() else {
            throw Abort(.notFound, reason: "PantryProduct with ID doesn't exist")
        }
        
        try await pantryProduct.delete(on: db)
    }
    
    // MARK: - Transaction
    
    func createPantryTransaction(pantryTransaction: PantryTransaction, on db: any Database) async throws -> PantryTransaction {
        try await pantryTransaction.save(on: db)
        
        return pantryTransaction
    }
    
    func deletePantryTransaction(id: UUID, on db: any Database) async throws {
        guard let pantryTransaction = try await PantryTransaction.query(on: db)
            .filter(\.$id == id).first() else {
            throw Abort(.notFound, reason: "PantryTransaction with ID doesn't exist")
        }
        
        try await pantryTransaction.delete(on: db)
    }
}
