//
//  PantryBatchController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor
import KarenShared

struct PantryBatchController: RouteCollection {
    //TODO: Make Global
    let pantryService = PantryService()
    let baseRoute: PathComponent = .init(stringLiteral: KarenShared.PantryBatch.baseRoute)
    
    func boot(routes: any RoutesBuilder) throws {
        routes.post(baseRoute, use: self.create)
        routes.get(baseRoute, use: self.getAll)
        routes.get(baseRoute, .parameter("id"), use: getByID)
        routes.put(baseRoute, .parameter("id"), use: update)
        routes.delete(baseRoute, .parameter("id"), use: delete)
    }
    
    func create(req: Request) async throws -> KarenShared.PantryBatch.DTO {
        let data = try req.content.decode(KarenShared.PantryBatch.DTO.self)
    
        let createdPantryBatch = try await pantryService.createPantryBatch(pantryBatch: data.toModel(), on: req.db)
        
        return try KarenShared.PantryBatch.DTO(model: createdPantryBatch)
    }
    
    func update(req: Request) async throws -> KarenShared.PantryBatch.DTO {
        let data = try req.content.decode(KarenShared.PantryBatch.DTO.self)
        
        let updatedPantryBatch = try await pantryService.updatePantryBatch(pantryBatch: data.toModel(), on: req.db)
        
        return try KarenShared.PantryBatch.DTO(model: updatedPantryBatch)
        
    }
    
    func getAll(req: Request) async throws -> [KarenShared.PantryBatch.DTO] {
        let pantryBatches = try await pantryService.getAllPantryBatch(on: req.db)
        
        let response: [KarenShared.PantryBatch.DTO] = try pantryBatches.map { pantryBatch in
            
            return try KarenShared.PantryBatch.DTO(model: pantryBatch)
        }
        
        return response
    }
    
    func getByID(req: Request) async throws -> KarenShared.PantryBatch.DTO{
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let pantryBatch = try await pantryService.getPantryBatchById(id: id, on: req.db)
        
        return try KarenShared.PantryBatch.DTO(model: pantryBatch)
    }
    
    func delete(req: Request) async throws -> HTTPStatus{
        let id = try req.parameters.require("id", as: UUID.self)
        
        try await pantryService.deletePantryBatch(id: id, on: req.db)
        
        return .noContent
    }
}
