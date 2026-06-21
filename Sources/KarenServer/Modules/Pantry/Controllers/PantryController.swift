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
        routes.get(baseRoute, "overview", use: getOverviewOfAll)
        routes.get(baseRoute, .parameter("id"), use: getByID)
        routes.put(baseRoute, .parameter("id"), use: update)
        routes.delete(baseRoute, .parameter("id"), use: delete)
        
        routes.post(baseRoute, .parameter("id"), "add", use: addBatch)
        routes.get(baseRoute, .parameter("id"), "batches", use: getBatches)
        routes.get(baseRoute, .parameter("id"), "overview", use: getOverviewByPantryID)
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
    
    func addBatch(req: Request) async throws -> KarenShared.PantryBatch {
        let pantryId = try req.parameters.require("id", as: UUID.self)
        let data = try req.content.decode(KarenShared.AddBatchToPantryRequest.self)
        
        let createdBatch = try await pantryService.addBatchToPantry(
            pantryId: pantryId,
            request: data,
            on: req.db
        )
        
        return try KarenShared.PantryBatch(model: createdBatch)
    }
    
    func getBatches(req: Request) async throws -> [KarenShared.PantryBatch] {
        let pantryId = try req.parameters.require("id", as: UUID.self)
        
        let batches = try await pantryService.getPantryBatches(pantryId: pantryId, on: req.db)
        
        return try batches.map { batch in
            try KarenShared.PantryBatch(model: batch)
        }
    }
    
    func getOverviewByPantryID(req: Request) async throws -> KarenShared.PantryOverview {
        let pantryId = try req.parameters.require("id", as: UUID.self)
        
        return try await pantryService.getOverviewById(pantryId: pantryId, on: req.db)
    }
    
    func getOverviewOfAll(req: Request) async throws -> KarenShared.PantryOverview {
        try await pantryService.getOverview(on: req.db)
    }
}
