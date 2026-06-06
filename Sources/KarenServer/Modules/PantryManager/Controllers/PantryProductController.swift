//
//  PantryProductController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Vapor

struct PantryProductController: RouteCollection {
    //TODO: Make Global
    let pantryService = PantryService()
    let baseRoute: PathComponent = "products"
    
    func boot(routes: any RoutesBuilder) throws {
        routes.post(baseRoute, use: self.create)
        routes.get(baseRoute, use: self.getAll)
        routes.get(baseRoute, .parameter("id"), use: getByID)
        routes.delete(baseRoute, .parameter("id"), use: delete)
    }
    
    func create(req: Request) async throws -> PantryDTO.PantryProduct{
        let data = try req.content.decode(PantryDTO.PantryProduct.self)
    
        let createdPantryProduct = try await pantryService.createPantryProduct(pantryProduct: data.toModel(), on: req.db)
        
        return try PantryDTO.PantryProduct(model: createdPantryProduct)
    }
    
    func update(req: Request) async throws -> PantryDTO.PantryProduct {
        let data = try req.content.decode(PantryDTO.PantryProduct.self)
        
        let updatedPantryProduct = try await pantryService.updatePantryProduct(pantryProduct: data.toModel(), on: req.db)
        
        return try PantryDTO.PantryProduct(model: updatedPantryProduct)
        
    }
    
    func getAll(req: Request) async throws -> [PantryDTO.PantryProduct] {
        let pantryProducts = try await pantryService.getAllPantryProduct(on: req.db)
        
        var response: [PantryDTO.PantryProduct] = try pantryProducts.map { pantryProduct in
            
            return try PantryDTO.PantryProduct(model: pantryProduct)
        }
        
        return response
    }
    
    func getByID(req: Request) async throws -> PantryDTO.PantryProduct {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let pantryProduct = try await pantryService.getPantryProductById(id: id, on: req.db)
        
        return try PantryDTO.PantryProduct(model: pantryProduct)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        try await pantryService.deletePantryProduct(id: id, on: req.db)
        
        return .noContent
    }
}
