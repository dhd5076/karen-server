//
//  PantryController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

struct PantryController {
    //TODO: Make Global
    let pantryService = PantryService()
    
    func create(req: Request) async throws -> PantryDTO.CreatePantryResponse{
        let data = try req.content.decode(PantryDTO.CreatePantryRequest.self)
        
        let pantry = Pantry(
            name: data.name
        )
        
        let createdPantry = try await pantryService.createPantry(pantry: pantry, on: req.db)
        
        guard let id = createdPantry.id else {
            throw Abort(.internalServerError, reason: "Created Pantry missing ID")
        }
        
        return PantryDTO.CreatePantryResponse(id: id)
    }
}
