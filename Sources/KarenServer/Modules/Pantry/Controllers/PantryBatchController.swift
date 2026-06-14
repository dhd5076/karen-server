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
        routes.post(baseRoute, .parameter("id"), "consume", use: consume)
    }
    
    func create(req: Request) async throws -> KarenShared.PantryBatch {
        let data = try req.content.decode(KarenShared.PantryBatch.self)
    
        let createdPantryBatch = try await pantryService.createPantryBatch(pantryBatch: data.toModel(), on: req.db)
        
        return try KarenShared.PantryBatch(model: createdPantryBatch)
    }
    
    func update(req: Request) async throws -> KarenShared.PantryBatch {
        let data = try req.content.decode(KarenShared.PantryBatch.self)
        
        let updatedPantryBatch = try await pantryService.updatePantryBatch(pantryBatch: data.toModel(), on: req.db)
        
        return try KarenShared.PantryBatch(model: updatedPantryBatch)
        
    }
    
    func getAll(req: Request) async throws -> [KarenShared.PantryBatch] {
        let pantryBatches = try await pantryService.getAllPantryBatch(on: req.db)
        
        let response: [KarenShared.PantryBatch] = try pantryBatches.map { pantryBatch in
            
            return try KarenShared.PantryBatch(model: pantryBatch)
        }
        
        return response
    }
    
    func getByID(req: Request) async throws -> KarenShared.PantryBatch{
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let pantryBatch = try await pantryService.getPantryBatchById(id: id, on: req.db)
        
        return try KarenShared.PantryBatch(model: pantryBatch)
    }
    
    func delete(req: Request) async throws -> HTTPStatus{
        let id = try req.parameters.require("id", as: UUID.self)
        
        try await pantryService.deletePantryBatch(id: id, on: req.db)
        
        return .noContent
    }

    func consume(req: Request) async throws -> KarenShared.PantryBatch {
        let id = try req.parameters.require("id", as: UUID.self)
        let data = try req.content.decode(KarenShared.ConsumePantryBatchRequest.self)

        let updatedBatch = try await pantryService.consumePantryBatch(
            batchId: id,
            request: data,
            on: req.db
        )

        return try KarenShared.PantryBatch(model: updatedBatch)
    }
}
