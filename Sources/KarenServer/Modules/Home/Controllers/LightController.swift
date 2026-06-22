//
//  LightController.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/22/26.
//

import Vapor
import KarenShared

struct LightController: RouteCollection {
    let lightService = LightService()
    let baseRoute: PathComponent = .init(stringLiteral: KarenShared.Light.baseRoute)
    
    func boot(routes: any RoutesBuilder) throws {
        routes.get(baseRoute, use: getAll)
        routes.post(baseRoute, .parameter("id"), "turn-on", use: turnOn)
        routes.post(baseRoute, .parameter("id"), "turn-off", use: turnOff)
    }
    
    func getAll(req: Request) async throws -> [KarenShared.Light] {
        try await lightService.getLights(on: req.client)
    }
    
    func turnOn(req: Request) async throws -> HTTPStatus {
        let id = try req.parameters.require("id")
        
        try await lightService.turnOnLight(id: id, on: req.client)
        
        return .noContent
    }
    
    func turnOff(req: Request) async throws -> HTTPStatus {
        let id = try req.parameters.require("id")
        
        try await lightService.turnOffLight(id: id, on: req.client)
        
        return .noContent
    }
}
