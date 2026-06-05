//
//  PantryTransactionController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

struct PantryTransactionController {
    
    let pantryService = PantryService()
    
    func create(req: Request) async throws -> PantryDTO.CreatePantryTransactionResponse{
        let data = try req.content.decode(PantryDTO.CreatePantryTransactionRequest.self)
        
        let pantryTransaction = PantryTransaction(
            type: data.type,
            product: data.product,
            batch: data.batch,
            fromPantry: data.fromPantry,
            toPantry: data.toPantry,
            quantity: data.quantity,
            note: data.note
        )
        
        let createedPantryTransaction = try await pantryService.createPantryTransaction(pantryTransaction: pantryTransaction, on: req.db)
        
        guard let id = createedPantryTransaction.id else {
            throw Abort(.internalServerError, reason: "Created PantryTransaction missing ID")
        }
        
        return PantryDTO.CreatePantryTransactionResponse(id: id)
    }
}
