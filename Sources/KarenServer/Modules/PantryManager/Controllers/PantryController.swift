//
//  PantryController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

struct PantryController: RouteCollection {
    //TODO: Make Global
    let pantryService = PantryService()
    let baseRoute: PathComponent = "pantries"
    
    func boot(routes: any RoutesBuilder) throws {
        routes.post(baseRoute, use: self.create)
        routes.get(baseRoute, use: self.getAll)
        routes.get(baseRoute, .parameter("id"), use: getByID)
        routes.delete(baseRoute, .parameter("id"), use: delete)
    }
    
    func create(req: Request) async throws -> PantryDTO.Pantry{
        let data = try req.content.decode(PantryDTO.Pantry.self)
    
        let createdPantry = try await pantryService.createPantry(pantry: data.toModel(), on: req.db)
        
        return try PantryDTO.Pantry(model: createdPantry)
    }
    
    func update(req: Request) async throws -> PantryDTO.Pantry {
        let data = try req.content.decode(PantryDTO.Pantry.self)
        
        let updatedPantry = try await pantryService.updatePantry(pantry: data.toModel(), on: req.db)
        
        return try PantryDTO.Pantry(model: updatedPantry)
        
    }
    
    func getAll(req: Request) async throws -> [PantryDTO.Pantry] {
        let pantries = try await pantryService.getAllPantry(on: req.db)
        
        var response: [PantryDTO.Pantry] = try pantries.map { pantry in
            
            return try PantryDTO.Pantry(model: pantry)
        }
        
        return response
    }
    
    func getByID(req: Request) async throws -> PantryDTO.Pantry {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let pantry = try await pantryService.getPantryById(id: id, on: req.db)
        
        return try PantryDTO.Pantry(model: pantry)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        try await pantryService.deletePantry(id: id, on: req.db)
        
        return .noContent
    }
}
