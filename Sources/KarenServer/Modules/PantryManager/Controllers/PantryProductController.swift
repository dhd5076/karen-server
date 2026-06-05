//
//  PantryProductController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

struct PantryProductController {
    //TODO: make Global
    let pantryService = PantryService()
    
    func create(req: Request) async throws -> PantryDTO.CreatePantryProductResponse{
        let data = try req.content.decode(PantryDTO.CreatePantryProductRequest.self)
        
        let pantryProduct = PantryProduct(
            name: data.name,
            unit: data.unit,
            proteinPerUnit: data.proteinPerUnit,
            carbsPerUnit: data.carbsPerUnit,
            fatPerUnit: data.fatPerUnit,
            shelfLife: data.shelfLife
        )
        
        let createdPantryProduct = try await pantryService.createPantryProduct(pantryProduct: pantryProduct, on: req.db)
        
        guard let id = createdPantryProduct.id else {
            throw Abort(.internalServerError, reason: "Created PantryProduct missing ID")
        }
        
        return PantryDTO.CreatePantryProductResponse(id: id)    
    }
}
