//
//  PantryTransactionController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor
import KarenShared

struct PantryTransactionController: RouteCollection {
    //TODO: Make Global
    let pantryService = PantryService()
    let baseRoute: PathComponent = .init(stringLiteral: KarenShared.PantryTransaction.baseRoute)
    
    func boot(routes: any RoutesBuilder) throws {
        routes.post(baseRoute, use: self.create)
        routes.get(baseRoute, use: self.getAll)
        routes.get(baseRoute, .parameter("id"), use: getByID)
        routes.put(baseRoute, .parameter("id"), use: update)
        routes.delete(baseRoute, .parameter("id"), use: delete)
    }
    
    func create(req: Request) async throws -> KarenShared.PantryTransaction.DTO {
        let data = try req.content.decode(KarenShared.PantryTransaction.DTO.self)
    
        let createdPantryTransaction = try await pantryService.createPantryTransaction(pantryTransaction: data.toModel(), on: req.db)
        
        return try KarenShared.PantryTransaction.DTO(model: createdPantryTransaction)
    }
    
    func update(req: Request) async throws -> KarenShared.PantryTransaction.DTO {
        let data = try req.content.decode(KarenShared.PantryTransaction.DTO.self)
        
        let updatedPantryTransaction = try await pantryService.updatePantryTransaction(pantryTransaction: data.toModel(), on: req.db)
        
        return try KarenShared.PantryTransaction.DTO(model: updatedPantryTransaction)
        
    }
    
    func getAll(req: Request) async throws -> [KarenShared.PantryTransaction.DTO] {
        let pantryTransactions = try await pantryService.getAllPantryTransaction(on: req.db)
        
        let response: [KarenShared.PantryTransaction.DTO] = try pantryTransactions.map { pantryTransaction in
            
            return try KarenShared.PantryTransaction.DTO(model: pantryTransaction)
        }
        
        return response
    }
    
    func getByID(req: Request) async throws -> KarenShared.PantryTransaction.DTO {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let pantryTransaction = try await pantryService.getPantryTransactionById(id: id, on: req.db)
        
        return try KarenShared.PantryTransaction.DTO(model: pantryTransaction)
    }
    
    func delete(req: Request) async throws -> HTTPStatus{
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        try await pantryService.deletePantry(id: id, on: req.db)
        
        return .noContent
    }
}
