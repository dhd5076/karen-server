//
//  PantryBatchController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

struct PantryBatchController {
    //TODO: Make Global
    let pantryService = PantryService()
    
    func create(req: Request) async throws -> PantryDTO.PantryBatch {
        let data = try req.content.decode(PantryDTO.PantryBatch.self)
    
        let createdPantryBatch = try await pantryService.createPantryBatch(pantryBatch: data.toModel(), on: req.db)
        
        return try PantryDTO.PantryBatch(model: createdPantryBatch)
    }
    
    func update(req: Request) async throws -> PantryDTO.PantryBatch {
        let data = try req.content.decode(PantryDTO.PantryBatch.self)
        
        let updatedPantryBatch = try await pantryService.updatePantryBatch(pantryBatch: data.toModel(), on: req.db)
        
        return try PantryDTO.PantryBatch(model: updatedPantryBatch)
        
    }
    
    func getAll(req: Request) async throws -> [PantryDTO.PantryBatch] {
        let pantryBatches = try await pantryService.getAllPantryBatch(on: req.db)
        
        var response: [PantryDTO.PantryBatch] = try pantryBatches.map { pantryBatch in
            
            return try PantryDTO.PantryBatch(model: pantryBatch)
        }
        
        return response
    }
    
    func getByID(req: Request) async throws -> PantryDTO.PantryBatch {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let pantryBatch = try await pantryService.getPantryBatchById(id: id, on: req.db)
        
        return try PantryDTO.PantryBatch(model: pantryBatch)
    }
    
    func delete(req: Request) async throws {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        try await pantryService.deletePantryBatch(id: id, on: req.db)
    }
}
