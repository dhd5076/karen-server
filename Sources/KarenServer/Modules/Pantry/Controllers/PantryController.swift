//
//  PantryController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor
import KarenShared

struct PantryController: RouteCollection {
    //TODO: Make Global
    let pantryService = PantryService()
    let baseRoute: PathComponent = .init(stringLiteral: KarenShared.Pantry.baseRoute)
    
    func boot(routes: any RoutesBuilder) throws {
        routes.post(baseRoute, use: self.create)
        routes.get(baseRoute, use: self.getAll)
        routes.get(baseRoute, .parameter("id"), use: getByID)
        routes.put(baseRoute, .parameter("id"), use: update)
        routes.delete(baseRoute, .parameter("id"), use: delete)
    }
    
    func create(req: Request) async throws -> KarenShared.Pantry {
        let data = try req.content.decode(KarenShared.Pantry.self)
    
        let createdPantry = try await pantryService.createPantry(pantry: data.toModel(), on: req.db)
        
        return try KarenShared.Pantry(model: createdPantry)
    }
    
    func update(req: Request) async throws -> KarenShared.Pantry {
        let data = try req.content.decode(KarenShared.Pantry.self)
        
        let updatedPantry = try await pantryService.updatePantry(pantry: data.toModel(), on: req.db)
        
        return try KarenShared.Pantry(model: updatedPantry)
        
    }
    
    func getAll(req: Request) async throws -> [KarenShared.Pantry] {
        let pantries = try await pantryService.getAllPantry(on: req.db)
        
        let response: [KarenShared.Pantry] = try pantries.map { pantry in
            
            return try KarenShared.Pantry(model: pantry)
        }
        
        return response
    }
    
    func getByID(req: Request) async throws -> KarenShared.Pantry {
        let id = try req.parameters.require("id", as: UUID.self)
        
        let pantry = try await pantryService.getPantryById(id: id, on: req.db)
        
        return try KarenShared.Pantry(model: pantry)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let id = try req.parameters.require("id", as: UUID.self)
        
        try await pantryService.deletePantry(id: id, on: req.db)
        
        return .noContent
    }
}
