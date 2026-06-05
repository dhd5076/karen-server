//
//  PantryBatchController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

struct PantryBatchController {
    //TODO: Make global
    let pantryService = PantryService()
    
    func create(req: Request) async throws -> PantryDTO.CreatePantryBatchResponse{
        let data = try req.content.decode(PantryDTO.CreatePantryBatchRequest.self)
        
        let pantryBatch = PantryBatch(
            product: data.product,
            quantity: data.quantity,
            source: data.source,
            aquiredAt: data.aquiredAt
        )
        
        let createdPantryBatch = try await pantryService.createPantryBatch(pantryBatch: pantryBatch, on: req.db)
        
        guard let id = createdPantryBatch.id else {
            throw Abort(.internalServerError, reason: "Created PantryBatch missing ID")
        }
        
        return PantryDTO.CreatePantryBatchResponse(id: id)
    }
}
