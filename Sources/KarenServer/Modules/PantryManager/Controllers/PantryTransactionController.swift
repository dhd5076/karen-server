//
//  PantryTransactionController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

struct PantryTransactionController: RouteCollection {
    //TODO: Make Global
    let pantryService = PantryService()
    let baseRoute: PathComponent = "transactions"
    
    func boot(routes: any RoutesBuilder) throws {
        routes.post(baseRoute, use: self.create)
        routes.get(baseRoute, use: self.getAll)
        routes.get(baseRoute, .parameter("id"), use: getByID)
        routes.delete(baseRoute, .parameter("id"), use: delete)
    }
    
    func create(req: Request) async throws -> PantryDTO.PantryTransaction{
        let data = try req.content.decode(PantryDTO.PantryTransaction.self)
    
        let createdPantryTransaction = try await pantryService.createPantryTransaction(pantryTransaction: data.toModel(), on: req.db)
        
        return try PantryDTO.PantryTransaction(model: createdPantryTransaction)
    }
    
    func update(req: Request) async throws -> PantryDTO.PantryTransaction {
        let data = try req.content.decode(PantryDTO.PantryTransaction.self)
        
        let updatedPantryTransaction = try await pantryService.updatePantryTransaction(pantryTransaction: data.toModel(), on: req.db)
        
        return try PantryDTO.PantryTransaction(model: updatedPantryTransaction)
        
    }
    
    func getAll(req: Request) async throws -> [PantryDTO.PantryTransaction] {
        let pantryTransactions = try await pantryService.getAllPantryTransaction(on: req.db)
        
        var response: [PantryDTO.PantryTransaction] = try pantryTransactions.map { pantryTransaction in
            
            return try PantryDTO.PantryTransaction(model: pantryTransaction)
        }
        
        return response
    }
    
    func getByID(req: Request) async throws -> PantryDTO.PantryTransaction {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let pantryTransaction = try await pantryService.getPantryTransactionById(id: id, on: req.db)
        
        return try PantryDTO.PantryTransaction(model: pantryTransaction)
    }
    
    func delete(req: Request) async throws -> HTTPStatus{
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        try await pantryService.deletePantry(id: id, on: req.db)
        
        return .noContent
    }
}
